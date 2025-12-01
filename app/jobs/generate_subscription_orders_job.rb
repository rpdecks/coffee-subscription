class GenerateSubscriptionOrdersJob < ApplicationJob
  queue_as :default

  def perform
    # Find all active subscriptions that are due for delivery
    subscriptions = Subscription.active
                                .where("next_delivery_date <= ?", Date.today)
                                .includes(:user, :subscription_plan, :shipping_address, :payment_method)

    generated_count = 0
    failed_count = 0

    subscriptions.each do |subscription|
      begin
        generator = SubscriptionOrderGenerator.new(subscription)
        if generator.generate_order
          generated_count += 1
        else
          failed_count += 1
        end
      rescue => e
        Rails.logger.error("Failed to generate order for subscription #{subscription.id}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        failed_count += 1
        # Continue processing other subscriptions even if one fails
        next
      end
    end

    Rails.logger.info("Order generation complete: #{generated_count} successful, #{failed_count} failed")
  end
end
