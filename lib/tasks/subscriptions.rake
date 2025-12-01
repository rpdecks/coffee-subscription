namespace :subscriptions do
  desc "Generate orders for subscriptions due for delivery"
  task generate_orders: :environment do
    puts "Checking for subscriptions due for delivery..."
    
    count = Subscription.active.where("next_delivery_date <= ?", Date.today).count
    puts "Found #{count} subscriptions due for delivery"
    
    GenerateSubscriptionOrdersJob.perform_now
    
    puts "Finished generating subscription orders"
  end

  desc "Preview subscriptions due for delivery without creating orders"
  task preview: :environment do
    subscriptions = Subscription.active
                                .where("next_delivery_date <= ?", Date.today)
                                .includes(:user, :subscription_plan)
    
    puts "\n=== Subscriptions Due for Delivery (#{subscriptions.count}) ===\n"
    
    if subscriptions.any?
      subscriptions.each do |sub|
        puts "ID: #{sub.id}"
        puts "  Customer: #{sub.user.full_name} (#{sub.user.email})"
        puts "  Plan: #{sub.subscription_plan.name} (#{sub.subscription_plan.frequency})"
        puts "  Next Delivery: #{sub.next_delivery_date}"
        puts "  Quantity: #{sub.quantity} bag(s)"
        puts "  Bag Size: #{sub.bag_size}"
        puts "  Has Address: #{sub.shipping_address.present?}"
        puts "  Has Payment: #{sub.payment_method.present?}"
        puts ""
      end
    else
      puts "No subscriptions due for delivery today."
    end
  end
end
