namespace :db do
  desc "Seed test orders for a user"
  task seed_orders: :environment do
    user = User.find_by(email: "rpdecks@gmail.com")
    
    unless user
      puts "User rpdecks@gmail.com not found!"
      exit
    end

    # Create a subscription plan if it doesn't exist
    plan = SubscriptionPlan.first_or_create!(
      name: "Monthly Coffee Box",
      description: "Fresh roasted coffee delivered monthly",
      price_cents: 2999,
      frequency: :monthly,
      bags_per_delivery: 2,
      active: true
    )

    # Create a subscription for the user
    subscription = user.subscriptions.first_or_create!(
      subscription_plan: plan,
      status: :active,
      current_period_start: 1.month.ago,
      current_period_end: 1.month.from_now,
      next_delivery_date: 1.week.from_now
    )

    # Create some products
    products = []
    [
      { name: "Ethiopian Yirgacheffe", price: 1599, description: "Bright, fruity, floral notes" },
      { name: "Colombian Supremo", price: 1499, description: "Smooth, balanced, chocolate notes" },
      { name: "Sumatra Mandheling", price: 1699, description: "Earthy, full-bodied, herbal" }
    ].each do |product_data|
      products << Product.find_or_create_by!(name: product_data[:name]) do |p|
        p.description = product_data[:description]
        p.product_type = :coffee
        p.price_cents = product_data[:price]
        p.weight_oz = 12.0
        p.inventory_count = 100
        p.active = true
      end
    end

    # Get user's default addresses
    shipping_address = user.addresses.where(address_type: :shipping, is_default: true).first
    payment_method = user.payment_methods.where(is_default: true).first

    # Create 5 orders with different statuses
    order_data = [
      { 
        status: :delivered, 
        created_at: 3.months.ago,
        shipped_at: 3.months.ago + 1.day,
        delivered_at: 3.months.ago + 4.days,
        products: [products[0], products[1]]
      },
      { 
        status: :delivered, 
        created_at: 2.months.ago,
        shipped_at: 2.months.ago + 1.day,
        delivered_at: 2.months.ago + 3.days,
        products: [products[1]]
      },
      { 
        status: :shipped, 
        created_at: 1.month.ago,
        shipped_at: 1.month.ago + 1.day,
        products: [products[0], products[2]]
      },
      { 
        status: :roasting, 
        created_at: 5.days.ago,
        products: [products[2]]
      },
      { 
        status: :processing, 
        created_at: 1.day.ago,
        products: [products[0]]
      }
    ]

    order_data.each_with_index do |data, index|
      # Generate tracking number for shipped/delivered orders
      tracking_number = if data[:status].in?([:shipped, :delivered])
        "1Z999AA1#{rand(10000000000..99999999999)}"
      else
        nil
      end

      order = Order.create!(
        user: user,
        subscription: subscription,
        order_number: "ORD-#{Time.now.to_i}-#{SecureRandom.hex(3).upcase}",
        order_type: :subscription,
        status: data[:status],
        subtotal_cents: 0,
        shipping_cents: 599,
        tax_cents: 0,
        total_cents: 0,
        shipping_address_id: shipping_address&.id,
        payment_method_id: payment_method&.id,
        tracking_number: tracking_number,
        created_at: data[:created_at],
        shipped_at: data[:shipped_at],
        delivered_at: data[:delivered_at]
      )

      # Add order items
      subtotal = 0
      data[:products].each do |product|
        OrderItem.create!(
          order: order,
          product: product,
          quantity: 1,
          price_cents: product.price_cents,
          grind_type: [:whole_bean, :coarse, :medium_grind, :fine, :espresso].sample
        )
        subtotal += product.price_cents
      end

      # Update order totals
      tax = (subtotal * 0.08).to_i
      order.update!(
        subtotal_cents: subtotal,
        tax_cents: tax,
        total_cents: subtotal + order.shipping_cents + tax
      )

      puts "Created order #{order.order_number} - #{order.status} - $#{order.total_cents / 100.0}"
    end

    puts "\n✅ Successfully created #{order_data.length} orders for #{user.email}"
  end
end
