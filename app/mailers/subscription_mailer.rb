class SubscriptionMailer < ApplicationMailer
  default from: ENV.fetch("SENDGRID_FROM_EMAIL", "subscriptions@coffeeshop.com")

  def subscription_created(subscription)
    @subscription = subscription
    @customer = subscription.user
    @plan = subscription.subscription_plan

    mail(
      to: @customer.email,
      subject: "Welcome to your coffee subscription!"
    )
  end

  def subscription_paused(subscription)
    @subscription = subscription
    @customer = subscription.user
    @plan = subscription.subscription_plan

    mail(
      to: @customer.email,
      subject: "Your subscription has been paused"
    )
  end

  def subscription_resumed(subscription)
    @subscription = subscription
    @customer = subscription.user
    @plan = subscription.subscription_plan

    mail(
      to: @customer.email,
      subject: "Your subscription has been resumed"
    )
  end

  def subscription_cancelled(subscription)
    @subscription = subscription
    @customer = subscription.user
    @plan = subscription.subscription_plan

    mail(
      to: @customer.email,
      subject: "Your subscription has been cancelled"
    )
  end

  def upcoming_delivery(subscription)
    @subscription = subscription
    @customer = subscription.user
    @plan = subscription.subscription_plan
    @delivery_date = subscription.next_delivery_date

    mail(
      to: @customer.email,
      subject: "Your next coffee delivery is coming soon!"
    )
  end

  def payment_failed(subscription, invoice = nil)
    @subscription = subscription
    @customer = subscription.user
    @plan = subscription.subscription_plan
    @invoice = invoice
    @failed_count = subscription.failed_payment_count
    @update_payment_url = edit_dashboard_payment_methods_url

    mail(
      to: @customer.email,
      subject: "Payment failed for your coffee subscription"
    )
  end
end
