# frozen_string_literal: true

class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_stripe_signature
  before_action :check_event_idempotency

  def stripe
    case @event.type
    when "checkout.session.completed"
      handle_checkout_session_completed(@event.data.object)
    when "customer.subscription.created"
      handle_subscription_created(@event.data.object)
    when "customer.subscription.updated"
      handle_subscription_updated(@event.data.object)
    when "customer.subscription.deleted"
      handle_subscription_deleted(@event.data.object)
    when "invoice.payment_succeeded"
      handle_invoice_payment_succeeded(@event.data.object)
    when "invoice.payment_failed"
      handle_invoice_payment_failed(@event.data.object)
    when "payment_method.attached"
      handle_payment_method_attached(@event.data.object)
    else
      Rails.logger.info("Unhandled Stripe event type: #{@event.type}")
    end

    render json: { status: "success" }, status: :ok
  rescue => e
    Rails.logger.error("Stripe webhook error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    render json: { status: "error", message: e.message }, status: :bad_request
  ensure
    # Mark event as processed
    @webhook_event&.update(processed_at: Time.current) if @webhook_event && !@webhook_event.processed_at
  end

  private

  def check_event_idempotency
    return unless @event # Skip if event wasn't parsed

    # Check if we've already processed this event
    @webhook_event = WebhookEvent.find_or_initialize_by(stripe_event_id: @event.id)

    if @webhook_event.persisted? && @webhook_event.processed_at.present?
      Rails.logger.info("Webhook event #{@event.id} already processed at #{@webhook_event.processed_at}")
      render json: { status: "success", message: "Event already processed" }, status: :ok
      return
    end

    # Save the event record
    @webhook_event.event_type = @event.type
    @webhook_event.save!
  rescue => e
    Rails.logger.error("Error checking webhook idempotency: #{e.message}")
    # Continue processing even if idempotency check fails
  end

  def verify_stripe_signature
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)

    # In development/test without webhook secret, parse the event directly
    if endpoint_secret.blank? && (Rails.env.development? || Rails.env.test?)
      begin
        @event = Stripe::Event.construct_from(JSON.parse(payload, symbolize_names: true))
        return
      rescue JSON::ParserError => e
        Rails.logger.error("Stripe webhook JSON parse error: #{e.message}")
        render json: { status: "error", message: "Invalid payload" }, status: :bad_request
        return
      end
    end

    begin
      @event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError => e
      Rails.logger.error("Stripe webhook JSON parse error: #{e.message}")
      render json: { status: "error", message: "Invalid payload" }, status: :bad_request
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error("Stripe webhook signature verification failed: #{e.message}")
      render json: { status: "error", message: "Invalid signature" }, status: :bad_request
    end
  end

  def handle_checkout_session_completed(session)
    Rails.logger.info("Checkout session completed: #{session.id}")

    # Find user by customer ID
    user = User.find_by(stripe_customer_id: session.customer)
    return unless user

    # Get metadata
    metadata = session.metadata

    # Check if this is a one-time purchase or subscription
    if metadata["order_type"] == "one_time"
      handle_one_time_purchase(session, user, metadata)
    else
      handle_subscription_purchase(session, user, metadata)
    end
  end

  def handle_one_time_purchase(session, user, metadata)
    Rails.logger.info("Processing one-time purchase for session: #{session.id}")

    # Parse cart items from metadata
    cart_items = JSON.parse(metadata["cart_items"] || "[]")
    return if cart_items.empty?

    # Get shipping address from Stripe session
    shipping_details = session.shipping_details || session.shipping
    shipping_address = if shipping_details
      create_or_find_address(user, shipping_details)
    else
      user.addresses.shipping.first || user.addresses.first
    end

    # Create order
    order = user.orders.create!(
      order_type: :one_time,
      status: :pending,
      shipping_address: shipping_address,
      stripe_payment_intent_id: session.payment_intent
    )

    # Create order items
    cart_items.each do |item|
      product = Product.find_by(id: item["product_id"])
      next unless product

      quantity = item["quantity"].to_i
      order.order_items.create!(
        product: product,
        product_name: product.name,
        quantity: quantity,
        price_cents: product.price_cents,
        total_cents: product.price_cents * quantity
      )
    end

    # Calculate totals
    order.calculate_totals
    order.save!

    Rails.logger.info("Created one-time order #{order.order_number} from webhook")

    # Send confirmation email
    OrderMailer.order_confirmation(order).deliver_later

    # Update inventory
    order.order_items.each do |item|
      product = item.product
      if product.inventory_count.present?
        product.update!(inventory_count: product.inventory_count - item.quantity)
      end
    end
  end

  def handle_subscription_purchase(session, user, metadata)
    plan = SubscriptionPlan.find_by(id: metadata["subscription_plan_id"])
    return unless plan

    # Create subscription record if it doesn't exist
    subscription = user.subscriptions.find_or_initialize_by(
      stripe_subscription_id: session.subscription
    )

    if subscription.new_record?
      # Get shipping address from metadata or use first address
      shipping_address = if metadata["shipping_address_id"]
        user.addresses.find_by(id: metadata["shipping_address_id"])
      else
        user.addresses.shipping.first || user.addresses.first
      end

      subscription.assign_attributes(
        subscription_plan: plan,
        bag_size: metadata["bag_size"] || "12oz",
        quantity: 1,
        status: :active,
        next_delivery_date: Date.current.to_date + plan.frequency_in_days.days,
        shipping_address: shipping_address,
        payment_method: user.payment_methods.default.first || user.payment_methods.first
      )

      if subscription.save
        Rails.logger.info("Created subscription #{subscription.id} from webhook")
        SubscriptionMailer.subscription_created(subscription).deliver_later
      else
        Rails.logger.error("Failed to create subscription: #{subscription.errors.full_messages}")
      end
    end
  end

  def create_or_find_address(user, shipping_details)
    address_attributes = {
      address_type: :shipping,
      street_address: shipping_details.address.line1,
      street_address_2: shipping_details.address.line2,
      city: shipping_details.address.city,
      state: shipping_details.address.state,
      zip_code: shipping_details.address.postal_code,
      country: shipping_details.address.country || "US"
    }

    # Try to find existing address
    existing = user.addresses.find_by(
      street_address: address_attributes[:street_address],
      city: address_attributes[:city],
      state: address_attributes[:state],
      zip_code: address_attributes[:zip_code]
    )

    return existing if existing

    # Create new address
    user.addresses.create!(address_attributes)
  end

  def handle_subscription_created(stripe_subscription)
    Rails.logger.info("Subscription created: #{stripe_subscription.id}")

    user = User.find_by(stripe_customer_id: stripe_subscription.customer)
    return unless user

    # Subscription should already be created by checkout.session.completed
    # This is a backup handler
    subscription = user.subscriptions.find_by(stripe_subscription_id: stripe_subscription.id)
    return if subscription

    # Create from webhook if somehow missed
    metadata = stripe_subscription.metadata
    plan = SubscriptionPlan.find_by(id: metadata["subscription_plan_id"])
    return unless plan

    user.subscriptions.create!(
      subscription_plan: plan,
      stripe_subscription_id: stripe_subscription.id,
      bag_size: metadata["bag_size"] || "12oz",
      quantity: 1,
      status: :active,
      next_delivery_date: Date.current.to_date + plan.frequency_in_days.days,
      shipping_address: user.addresses.first,
      payment_method: user.payment_methods.default.first || user.payment_methods.first
    )
      .tap { |sub| SubscriptionMailer.subscription_created(sub).deliver_later }
  end

  def handle_subscription_updated(stripe_subscription)
    Rails.logger.info("Subscription updated: #{stripe_subscription.id}")

    subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
    return unless subscription

    # Update status based on Stripe subscription status
    new_status = case stripe_subscription.status
    when "active" then :active
    when "past_due" then :past_due
    when "canceled" then :cancelled
    when "unpaid" then :past_due
    when "paused" then :paused
    else subscription.status
    end

    subscription.update(status: new_status) if subscription.status != new_status
  end

  def handle_subscription_deleted(stripe_subscription)
    Rails.logger.info("Subscription deleted: #{stripe_subscription.id}")

    subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
    return unless subscription

    subscription.update(status: :cancelled, cancelled_at: Time.current)

    # Send cancellation confirmation email
    SubscriptionMailer.subscription_cancelled(subscription).deliver_later
  end

  def handle_invoice_payment_succeeded(invoice)
    Rails.logger.info("Invoice payment succeeded: #{invoice.id}")

    subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
    return unless subscription

    # Reset failed payment count on successful payment
    subscription.update(failed_payment_count: 0) if subscription.failed_payment_count > 0

    # Reactivate if it was past_due
    subscription.update(status: :active) if subscription.past_due?

    # Create order for this billing period
    CreateSubscriptionOrderJob.perform_later(subscription.id, invoice.id)
  end

  def handle_invoice_payment_failed(invoice)
    Rails.logger.error("Invoice payment failed: #{invoice.id}")

    subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
    return unless subscription

    # Update subscription status
    subscription.update(status: :past_due)

    # Track failed payment attempt
    subscription.increment!(:failed_payment_count) if subscription.respond_to?(:failed_payment_count)

    # Send payment failed email to customer
    SubscriptionMailer.payment_failed(subscription, invoice.to_hash).deliver_later

    # After 3 failed attempts, consider suspending
    if subscription.failed_payment_count.to_i >= 3
      Rails.logger.error("Subscription #{subscription.id} has #{subscription.failed_payment_count} failed payments - consider suspension")
      # Optionally auto-cancel after multiple failures
      # subscription.update(status: :cancelled)
      # SubscriptionMailer.suspended_due_to_payment(subscription).deliver_later
    end
  end

  def handle_payment_method_attached(payment_method)
    Rails.logger.info("Payment method attached: #{payment_method.id}")

    user = User.find_by(stripe_customer_id: payment_method.customer)
    return unless user

    # Save payment method details
    StripeService.send(:save_payment_method, user, payment_method, false)
  end
end
