# frozen_string_literal: true

class CreateSubscriptionOrderJob < ApplicationJob
  queue_as :default

  def perform(subscription_id, invoice_id = nil)
    subscription = Subscription.find(subscription_id)
    
    # Create order for this subscription billing period
    order = subscription.orders.build(
      user: subscription.user,
      order_number: generate_order_number,
      order_type: :subscription,
      status: :pending,
      total_cents: subscription.subscription_plan.price_cents,
      shipping_address: subscription.shipping_address,
      stripe_invoice_id: invoice_id
    )

    if order.save
      Rails.logger.info("Created order #{order.id} for subscription #{subscription.id}")
      
      # Update next delivery date
      subscription.update(
        next_delivery_date: subscription.next_delivery_date + subscription.frequency.days
      )

      # Send order confirmation email
      OrderMailer.order_confirmation(order).deliver_later
    else
      Rails.logger.error("Failed to create order for subscription #{subscription.id}: #{order.errors.full_messages}")
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("Subscription #{subscription_id} not found: #{e.message}")
  end

  private

  def generate_order_number
    "ORD-#{Time.current.to_i}-#{SecureRandom.hex(3).upcase}"
  end
end
