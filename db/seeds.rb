# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# PRODUCTION DATABASE PROTECTION
# Prevent accidental seeding of production database with test data
if Rails.env.production?
  puts "\n" + ("=" * 80)
  puts "WARNING: You are about to seed the PRODUCTION database!"
  puts "This will DELETE ALL existing data and create test/demo records."
  puts ("=" * 80)
  print "\nType 'DELETE ALL PRODUCTION DATA' (exactly) to continue: "

  confirmation = STDIN.gets.chomp

  unless confirmation == "DELETE ALL PRODUCTION DATA"
    puts "\n❌ Seeding cancelled. Production database was NOT modified."
    exit 0
  end

  puts "\n⚠️  Proceeding with production database seed..."
end

# Clear existing data in correct order to avoid FK constraints
puts "Clearing existing data..."
OrderItem.destroy_all
Order.destroy_all
Subscription.destroy_all
CoffeePreference.destroy_all
PaymentMethod.destroy_all
Address.destroy_all
SubscriptionPlan.destroy_all
Product.destroy_all
User.destroy_all

puts "Creating users..."

# Create admin users
robert_admin = User.create!(
  email: "rp@acercoffee.com",
  password: "ChangeMe123!",
  password_confirmation: "ChangeMe123!",
  first_name: "Robert",
  last_name: "Phillips",
  phone: "555-234-5678",
  role: :admin
)

katie_admin = User.create!(
  email: "kp@acercoffee.com",
  password: "ChangeMe123!",
  password_confirmation: "ChangeMe123!",
  first_name: "Katie",
  last_name: "Phillips",
  phone: "555-234-5679",
  role: :admin
)

# Create a few test customers for inner circle testing
test_customers = [
  {
    email: "test1@example.com",
    first_name: "Emma",
    last_name: "Johnson",
    phone: "555-100-0001"
  },
  {
    email: "test2@example.com",
    first_name: "Liam",
    last_name: "Williams",
    phone: "555-100-0002"
  },
  {
    email: "test3@example.com",
    first_name: "Olivia",
    last_name: "Brown",
    phone: "555-100-0003"
  }
]

customers = test_customers.map do |attrs|
  User.create!(
    email: attrs[:email],
    password: "TestPass123!",
    password_confirmation: "TestPass123!",
    first_name: attrs[:first_name],
    last_name: attrs[:last_name],
    phone: attrs[:phone],
    role: :customer,
    created_at: rand(30.days.ago..Time.now)
  )
end

puts "Created #{User.count} users (#{User.admin.count} admins, #{User.customer.count} customers)"

puts "Creating products..."

# Create coffee products
Product.create!([
  {
    name: "Ethiopian Yirgacheffe",
    description: "Bright and floral with notes of lemon and blueberry. Light to medium roast.",
    product_type: :coffee,
    price_cents: 1800,
    weight_oz: 12,
    inventory_count: 100,
    active: true
  },
  {
    name: "Colombian Supremo",
    description: "Well-balanced with chocolate and caramel notes. Medium roast.",
    product_type: :coffee,
    price_cents: 1600,
    weight_oz: 12,
    inventory_count: 150,
    active: true
  },
  {
    name: "Sumatra Mandheling",
    description: "Full-bodied with earthy and herbal notes. Dark roast.",
    product_type: :coffee,
    price_cents: 1900,
    weight_oz: 12,
    inventory_count: 80,
    active: true
  },
  {
    name: "Guatemala Antigua",
    description: "Smooth and complex with chocolate and spice. Medium-dark roast.",
    product_type: :coffee,
    price_cents: 1700,
    weight_oz: 12,
    inventory_count: 120,
    active: true
  },
  {
    name: "Costa Rica Tarrazu",
    description: "Crisp acidity with citrus and honey notes. Medium roast.",
    product_type: :coffee,
    price_cents: 1750,
    weight_oz: 12,
    inventory_count: 90,
    active: true
  }
])

# Create merch products
Product.create!([
  {
    name: "Acer Coffee Mug",
    description: "Ceramic mug with our logo. 12oz capacity.",
    product_type: :merch,
    price_cents: 1200,
    inventory_count: 50,
    active: true
  },
  {
    name: "Acer Coffee T-Shirt",
    description: "100% cotton t-shirt with Acer Coffee logo.",
    product_type: :merch,
    price_cents: 2400,
    inventory_count: 30,
    active: true
  }
])

puts "Created #{Product.count} products"

puts "Creating subscription plans..."

weekly_plan = SubscriptionPlan.create!(
  name: "Weekly - 1 Bag",
  description: "One 12oz bag delivered every week. Perfect for daily coffee drinkers.",
  frequency: :weekly,
  bags_per_delivery: 1,
  price_cents: 1800,
  active: true
)

biweekly_plan = SubscriptionPlan.create!(
  name: "Bi-Weekly - 2 Bags",
  description: "Two 12oz bags delivered every two weeks. Great for couples or heavy drinkers.",
  frequency: :biweekly,
  bags_per_delivery: 2,
  price_cents: 3400,
  active: true
)

monthly_plan = SubscriptionPlan.create!(
  name: "Monthly - 2 Bags",
  description: "Two 12oz bags delivered monthly. Ideal for moderate coffee consumption.",
  frequency: :monthly,
  bags_per_delivery: 2,
  price_cents: 3200,
  active: true
)

monthly_large_plan = SubscriptionPlan.create!(
  name: "Monthly - 4 Bags",
  description: "Four 12oz bags delivered monthly. Perfect for families or offices.",
  frequency: :monthly,
  bags_per_delivery: 4,
  price_cents: 6000,
  active: true
)

# Inactive plan for testing
SubscriptionPlan.create!(
  name: "Legacy Plan",
  description: "Old plan no longer offered to new customers.",
  frequency: :monthly,
  bags_per_delivery: 1,
  price_cents: 1500,
  active: false
)

puts "Created #{SubscriptionPlan.count} subscription plans"

puts "Creating addresses for customers..."

# Give most customers addresses
customers.sample(25).each do |customer|
  cities = [
    [ "Portland", "OR", "97201" ], [ "Seattle", "WA", "98101" ], [ "San Francisco", "CA", "94102" ],
    [ "Denver", "CO", "80202" ], [ "Austin", "TX", "78701" ], [ "Chicago", "IL", "60601" ],
    [ "Boston", "MA", "02108" ], [ "New York", "NY", "10001" ], [ "Los Angeles", "CA", "90001" ]
  ]

  city, state, zip = cities.sample

  Address.create!(
    user: customer,
    address_type: :shipping,
    street_address: "#{rand(100..9999)} #{[ 'Main', 'Oak', 'Pine', 'Elm', 'Maple' ].sample} #{[ 'St', 'Ave', 'Rd', 'Ln' ].sample}",
    city: city,
    state: state,
    zip_code: zip,
    country: "USA",
    is_default: true,
    created_at: customer.created_at + rand(1..30).days
  )
end

puts "Created #{Address.count} addresses"

puts "Creating payment methods..."

# Give customers with addresses payment methods
Address.all.map(&:user).uniq.each do |customer|
  PaymentMethod.create!(
    user: customer,
    card_brand: [ "Visa", "Mastercard", "Amex" ].sample,
    last_four: rand(1000..9999).to_s,
    exp_month: rand(1..12),
    exp_year: rand(2025..2030),
    is_default: true,
    stripe_payment_method_id: "pm_test_#{SecureRandom.hex(12)}",
    created_at: customer.created_at + rand(1..30).days
  )
end

puts "Created #{PaymentMethod.count} payment methods"

puts "Creating coffee preferences..."

# Give most customers coffee preferences
customers.sample(20).each do |customer|
  CoffeePreference.create!(
    user: customer,
    roast_level: [ :light, :medium_roast, :dark ].sample,
    grind_type: [ :whole_bean, :coarse, :medium_grind, :fine, :espresso ].sample,
    created_at: customer.created_at + rand(1..30).days
  )
end

puts "Created #{CoffeePreference.count} coffee preferences"

puts "Creating subscriptions..."

# Create subscriptions for customers with payment methods
subscription_plans = [ weekly_plan, biweekly_plan, monthly_plan, monthly_large_plan ]
customers_with_payment = PaymentMethod.all.map(&:user).uniq

# Active subscriptions (60%)
customers_with_payment.sample((customers_with_payment.count * 0.6).to_i).each do |customer|
  plan = subscription_plans.sample
  created_date = rand(90.days.ago..30.days.ago)

  Subscription.create!(
    user: customer,
    subscription_plan: plan,
    status: :active,
    quantity: [ 1, 2 ].sample,
    next_delivery_date: created_date + plan.frequency_in_days.days,
    created_at: created_date
  )
end

# Paused subscriptions (10%)
customers_with_payment.sample((customers_with_payment.count * 0.1).to_i).each do |customer|
  next if customer.subscriptions.any? # Don't duplicate

  plan = subscription_plans.sample
  created_date = rand(90.days.ago..60.days.ago)

  Subscription.create!(
    user: customer,
    subscription_plan: plan,
    status: :paused,
    quantity: [ 1, 2 ].sample,
    next_delivery_date: created_date + plan.frequency_in_days.days,
    created_at: created_date
  )
end

# Cancelled subscriptions (15%)
customers_with_payment.sample((customers_with_payment.count * 0.15).to_i).each do |customer|
  next if customer.subscriptions.any?

  plan = subscription_plans.sample
  created_date = rand(180.days.ago..90.days.ago)
  cancelled_date = created_date + rand(30..60).days

  Subscription.create!(
    user: customer,
    subscription_plan: plan,
    status: :cancelled,
    quantity: [ 1, 2 ].sample,
    next_delivery_date: cancelled_date,
    cancelled_at: cancelled_date,
    created_at: created_date
  )
end

puts "Created #{Subscription.count} subscriptions (#{Subscription.active.count} active, #{Subscription.paused.count} paused, #{Subscription.cancelled.count} cancelled)"

puts "Creating orders..."

coffee_products = Product.where(product_type: :coffee).to_a
all_statuses = [ :pending, :processing, :roasting, :shipped, :delivered ]

# Create historical orders for active subscriptions
Subscription.active.each do |subscription|
  # Create 3-8 past orders per subscription
  num_orders = rand(3..8)
  num_orders.times do |i|
    order_date = subscription.created_at + (i * subscription.subscription_plan.frequency_in_days).days
    break if order_date > Date.today

    status = order_date < 14.days.ago ? :delivered : all_statuses.sample

    order = Order.create!(
      user: subscription.user,
      subscription: subscription,
      order_number: "ORD-#{Date.today.year}-#{sprintf('%04d', Order.count + 1)}",
      order_type: :subscription,
      status: status,
      subtotal_cents: subscription.subscription_plan.price_cents,
      shipping_cents: 500,
      tax_cents: (subscription.subscription_plan.price_cents * 0.08).to_i,
      total_cents: subscription.subscription_plan.price_cents + 500 + (subscription.subscription_plan.price_cents * 0.08).to_i,
      shipping_address_id: subscription.user.addresses.first&.id,
      created_at: order_date
    )

    # Add order items
    subscription.subscription_plan.bags_per_delivery.times do
      OrderItem.create!(
        order: order,
        product: coffee_products.sample,
        quantity: 1,
        price_cents: 1800,
        created_at: order_date
      )
    end
  end
end

# Create some one-time orders (skip for now since subscription_id is required)
# customers_with_payment.sample(15).each do |customer|
#   order_date = rand(60.days.ago..Time.now)
#   status = order_date < 14.days.ago ? :delivered : all_statuses.sample
#   num_items = rand(1..4)
#
#   items_total = num_items * 1800
#
#   order = Order.create!(
#     user: customer,
#     order_number: "ORD-#{Date.today.year}-#{sprintf('%04d', Order.count + 1)}",
#     order_type: :one_time,
#     status: status,
#     subtotal_cents: items_total,
#     shipping_cents: 500,
#     tax_cents: (items_total * 0.08).to_i,
#     total_cents: items_total + 500 + (items_total * 0.08).to_i,
#     shipping_address_id: customer.addresses.first&.id,
#     created_at: order_date
#   )
#
#   num_items.times do
#     OrderItem.create!(
#       order: order,
#       product: coffee_products.sample,
#       quantity: 1,
#       price_cents: 1800,
#       created_at: order_date
#     )
#   end
# end

puts "Created #{Order.count} orders with #{OrderItem.count} items"

puts "\n✅ Seed data created successfully!"
puts ""
puts "=" * 60
puts "SUMMARY"
puts "=" * 60
puts "Users: #{User.count} (#{User.admin.count} admins, #{User.customer.count} customers)"
puts "Products: #{Product.count} (#{Product.where(product_type: :coffee).count} coffee, #{Product.where(product_type: :merch).count} merch)"
puts "Subscription Plans: #{SubscriptionPlan.count} (#{SubscriptionPlan.where(active: true).count} active)"
puts "Subscriptions: #{Subscription.count} (#{Subscription.active.count} active, #{Subscription.paused.count} paused, #{Subscription.cancelled.count} cancelled)"
puts "Orders: #{Order.count} (#{Order.where(status: :delivered).count} delivered, #{Order.where(status: :shipped).count} shipped, #{Order.where(status: [ :pending, :processing, :roasting ]).count} in progress)"
puts "Addresses: #{Address.count}"
puts "Payment Methods: #{PaymentMethod.count}"
puts "Coffee Preferences: #{CoffeePreference.count}"
puts ""
puts "=" * 60
puts "TEST ACCOUNTS"
puts "=" * 60
puts "Admin Accounts:"
puts "  - rp@acercoffee.com / ChangeMe123!"
puts "  - kp@acercoffee.com / ChangeMe123!"
puts ""
puts "Sample Customers:"
puts "  - test1@example.com / TestPass123!"
puts "  - test2@example.com / TestPass123!"
puts "  - test3@example.com / TestPass123!"
puts "=" * 60
