# frozen_string_literal: true

class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_stripe_signature

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
    render json: { status: "error", message: e.message }, status: :bad_request
  end

  private

  def verify_stripe_signature
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)

    # In development without webhook secret, parse the event directly
    if endpoint_secret.blank? && Rails.env.development?
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
    plan = SubscriptionPlan.find_by(id: metadata["subscription_plan_id"])
    return unless plan

    # Create subscription record if it doesn't exist
    subscription = user.subscriptions.find_or_initialize_by(
      stripe_subscription_id: session.subscription
    )

    if subscription.new_record?
      subscription.assign_attributes(
        subscription_plan: plan,
        bag_size: metadata["bag_size"] || "12oz",
        quantity: 1,
        status: :active,
        next_delivery_date: Date.today + (metadata["frequency"] || plan.frequency).to_i.days,
        shipping_address: user.addresses.first,
        payment_method: user.payment_methods.default.first || user.payment_methods.first
      )

      if subscription.save
        Rails.logger.info("Created subscription #{subscription.id} from webhook")
        # Send welcome email
        # SubscriptionMailer.welcome(subscription).deliver_later
      else
        Rails.logger.error("Failed to create subscription: #{subscription.errors.full_messages}")
      end
    end
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
      next_delivery_date: Date.today + (metadata["frequency"] || plan.frequency).to_i.days,
      shipping_address: user.addresses.first,
      payment_method: user.payment_methods.default.first || user.payment_methods.first
    )
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

    subscription.update(status: :cancelled)
    # Send cancellation email
    # SubscriptionMailer.cancelled(subscription).deliver_later
  end

  def handle_invoice_payment_succeeded(invoice)
    Rails.logger.info("Invoice payment succeeded: #{invoice.id}")

    subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
    return unless subscription

    # Create order for this billing period
    CreateSubscriptionOrderJob.perform_later(subscription.id, invoice.id)
  end

  def handle_invoice_payment_failed(invoice)
    Rails.logger.error("Invoice payment failed: #{invoice.id}")

    subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
    return unless subscription

    subscription.update(status: :past_due)
    # Send payment failed email
    # SubscriptionMailer.payment_failed(subscription).deliver_later
  end

  def handle_payment_method_attached(payment_method)
    Rails.logger.info("Payment method attached: #{payment_method.id}")

    user = User.find_by(stripe_customer_id: payment_method.customer)
    return unless user

    # Save payment method details
    StripeService.send(:save_payment_method, user, payment_method, false)
  end
end
