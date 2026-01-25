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

    case email_type
    when "order_confirmation"
      order = Order.includes(:order_items, :user).last
      OrderMailer.order_confirmation(order).deliver_now if order
    when "order_shipped"
      order = Order.includes(:order_items, :user).last
      OrderMailer.order_shipped(order).deliver_now if order
    when "subscription_created"
      subscription = Subscription.includes(:user, :subscription_plan).last
      SubscriptionMailer.subscription_created(subscription).deliver_now if subscription
    when "subscription_paused"
      subscription = Subscription.includes(:user, :subscription_plan).last
      SubscriptionMailer.subscription_paused(subscription).deliver_now if subscription
    when "subscription_resumed"
      subscription = Subscription.includes(:user, :subscription_plan).last
      SubscriptionMailer.subscription_resumed(subscription).deliver_now if subscription
    when "subscription_cancelled"
      subscription = Subscription.includes(:user, :subscription_plan).last
      SubscriptionMailer.subscription_cancelled(subscription).deliver_now if subscription
    when "payment_failed"
      subscription = Subscription.includes(:user, :subscription_plan).last
      if subscription
        SubscriptionMailer.payment_failed(subscription).deliver_now
      end
    when "contact_form"
      ContactMailer.contact_form(
        name: "Test User",
        email: "test@example.com",
        subject: "Test Contact Form",
        message: "This is a test message from the email preview system."
      ).deliver_now
    when "confirmation_instructions"
      current_user.send_confirmation_instructions
    when "reset_password_instructions"
      token = Devise.friendly_token
      Devise.mailer.reset_password_instructions(current_user, token).deliver_now
    when "password_change"
      Devise.mailer.password_change(current_user).deliver_now
    when "email_changed"
      Devise.mailer.email_changed(current_user).deliver_now
    end

    redirect_to email_tests_path, notice: "Test email sent! Check your browser for the preview."
  end

  private

  def require_admin!
    redirect_to root_path, alert: "Access denied" unless current_user.admin?
  end
end
