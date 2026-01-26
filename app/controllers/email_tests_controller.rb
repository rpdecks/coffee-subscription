class EmailTestsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @user = current_user
    @order = Order.includes(:order_items, :user).last
    @subscription = Subscription.includes(:user, :subscription_plan).last
  end

  def send_test_email
    email_type = params[:email_type]

    sent = false
    error_message = nil

    begin
      case email_type
      when "order_confirmation"
        order = Order.includes(:order_items, :user).last || ensure_test_order!
        sent = !!OrderMailer.order_confirmation(order).deliver_now if order
        error_message ||= "No order could be created for preview." unless sent
      when "order_shipped"
        order = Order.includes(:order_items, :user).last || ensure_test_order!
        sent = !!OrderMailer.order_shipped(order).deliver_now if order
        error_message ||= "No order could be created for preview." unless sent
      when "subscription_created"
        subscription = Subscription.includes(:user, :subscription_plan).last || ensure_test_subscription!
        sent = !!SubscriptionMailer.subscription_created(subscription).deliver_now if subscription
        error_message ||= "No subscription could be created for preview." unless sent
      when "subscription_paused"
        subscription = Subscription.includes(:user, :subscription_plan).last || ensure_test_subscription!
        sent = !!SubscriptionMailer.subscription_paused(subscription).deliver_now if subscription
        error_message ||= "No subscription could be created for preview." unless sent
      when "subscription_resumed"
        subscription = Subscription.includes(:user, :subscription_plan).last || ensure_test_subscription!
        sent = !!SubscriptionMailer.subscription_resumed(subscription).deliver_now if subscription
        error_message ||= "No subscription could be created for preview." unless sent
      when "subscription_cancelled"
        subscription = Subscription.includes(:user, :subscription_plan).last || ensure_test_subscription!
        sent = !!SubscriptionMailer.subscription_cancelled(subscription).deliver_now if subscription
        error_message ||= "No subscription could be created for preview." unless sent
      when "payment_failed"
        subscription = Subscription.includes(:user, :subscription_plan).last || ensure_test_subscription!
        sent = !!SubscriptionMailer.payment_failed(subscription).deliver_now if subscription
        error_message ||= "No subscription could be created for preview." unless sent
      when "contact_form"
        sent = !!ContactMailer.contact_form(
          name: "Test User",
          email: "test@example.com",
          subject: "Test Contact Form",
          message: "This is a test message from the email preview system."
        ).deliver_now
      when "confirmation_instructions"
        token = Devise.friendly_token
        sent = !!Devise.mailer.confirmation_instructions(current_user, token).deliver_now
      when "reset_password_instructions"
        token = Devise.friendly_token
        sent = !!Devise.mailer.reset_password_instructions(current_user, token).deliver_now
      when "password_change"
        sent = !!Devise.mailer.password_change(current_user).deliver_now
      when "email_changed"
        sent = !!Devise.mailer.email_changed(current_user).deliver_now
      else
        error_message = "Unknown email type: #{email_type.inspect}"
      end
    rescue => e
      Rails.logger.error("EmailTestsController failed to send #{email_type.inspect}: #{e.class}: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
      error_message = "Failed to send: #{e.class}: #{e.message}"
    end

    if sent
      redirect_to email_tests_path, notice: "Test email sent! Check your browser for the preview."
    else
      redirect_to email_tests_path, alert: (error_message || "Nothing was sent. Try again.")
    end
  end

  private

  def ensure_test_subscription!
    return nil if Rails.env.production?

    plan = SubscriptionPlan.active.order(:price_cents).first || ensure_test_subscription_plan!
    return nil unless plan

    Subscription.create!(
      user: current_user,
      subscription_plan: plan,
      status: :active,
      next_delivery_date: Date.current.to_date + plan.frequency_in_days.days
    )
  end

  def ensure_test_order!
    return nil if Rails.env.production?

    product = Product.coffee.active.first || ensure_test_product!
    return nil unless product

    shipping_address = current_user.addresses.shipping.first || current_user.addresses.create!(
      address_type: :shipping,
      street_address: "123 Maple St",
      city: "Knoxville",
      state: "TN",
      zip_code: "37902",
      country: "US",
      is_default: true
    )

    subscription = nil
    if Order.columns_hash["subscription_id"]&.null == false
      subscription = current_user.subscriptions.last || ensure_test_subscription!
      raise "Orders require a subscription_id but none could be created" unless subscription
    end

    order = Order.create!(
      user: current_user,
      subscription: subscription,
      order_type: :one_time,
      status: :processing,
      shipping_address: shipping_address
    )

    OrderItem.create!(
      order: order,
      product: product,
      quantity: 1
    )

    order.calculate_totals
    order.save!
    order
  end

  def ensure_test_product!
    return nil if Rails.env.production?

    Product.find_or_create_by!(name: "Test Coffee") do |p|
      p.product_type = :coffee
      p.roast_type = :signature
      p.price_cents = 1500
      p.active = true
      p.visible_in_shop = false
      p.inventory_count = 100
      p.description = "Test product for email previews."
      p.weight_oz = 12
    end
  end

  def ensure_test_subscription_plan!
    return nil if Rails.env.production?

    SubscriptionPlan.find_or_create_by!(name: "Test Subscription") do |plan|
      plan.frequency = :monthly
      plan.bags_per_delivery = 1
      plan.price_cents = 1500
      plan.active = true
      plan.description = "Test plan for email previews."
    end
  end

  def require_admin!
    redirect_to root_path, alert: "Access denied" unless current_user.admin?
  end
end
