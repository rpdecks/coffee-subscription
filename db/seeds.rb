# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data
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

# Create admin user
admin = User.create!(
  email: "admin@coffeeco.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Admin",
  last_name: "User",
  phone: "555-123-4567",
  role: :admin
)

# Create test customers
robert = User.create!(
  email: "rpdecks@gmail.com",
  password: "seedpass",
  password_confirmation: "seedpass",
  first_name: "Robert",
  last_name: "Phillips",
  phone: "555-234-5678",
  role: :customer
)

customer2 = User.create!(
  email: "jane@example.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Jane",
  last_name: "Smith",
  phone: "555-345-6789",
  role: :customer
)

puts "Created #{User.count} users"

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
    name: "Coffee Co. Mug",
    description: "Ceramic mug with our logo. 12oz capacity.",
    product_type: :merch,
    price_cents: 1200,
    inventory_count: 50,
    active: true
  },
  {
    name: "Coffee Co. T-Shirt",
    description: "100% cotton t-shirt with Coffee Co. logo.",
    product_type: :merch,
    price_cents: 2400,
    inventory_count: 30,
    active: true
  }
])

puts "Created #{Product.count} products"

puts "Creating subscription plans..."

SubscriptionPlan.create!([
  {
    name: "Weekly - 1 Bag",
    description: "One 12oz bag delivered every week. Perfect for daily coffee drinkers.",
    frequency: :weekly,
    bags_per_delivery: 1,
    price_cents: 1800,
    active: true
  },
  {
    name: "Bi-Weekly - 2 Bags",
    description: "Two 12oz bags delivered every two weeks. Great for couples or heavy drinkers.",
    frequency: :biweekly,
    bags_per_delivery: 2,
    price_cents: 3400,
    active: true
  },
  {
    name: "Monthly - 2 Bags",
    description: "Two 12oz bags delivered monthly. Ideal for moderate coffee consumption.",
    frequency: :monthly,
    bags_per_delivery: 2,
    price_cents: 3200,
    active: true
  },
  {
    name: "Monthly - 4 Bags",
    description: "Four 12oz bags delivered monthly. Perfect for families or offices.",
    frequency: :monthly,
    bags_per_delivery: 4,
    price_cents: 6000,
    active: true
  }
])

puts "Created #{SubscriptionPlan.count} subscription plans"

puts "Creating addresses for customers..."

Address.create!(
  user: robert,
  address_type: :shipping,
  street_address: "123 Main St",
  city: "Portland",
  state: "OR",
  zip_code: "97201",
  country: "USA",
  is_default: true
)

Address.create!(
  user: customer2,
  address_type: :shipping,
  street_address: "456 Oak Ave",
  city: "Seattle",
  state: "WA",
  zip_code: "98101",
  country: "USA",
  is_default: true
)

puts "Created #{Address.count} addresses"

puts "Creating payment methods..."

PaymentMethod.create!(
  user: robert,
  card_brand: "Visa",
  last_four: "4242",
  exp_month: 12,
  exp_year: 2028,
  is_default: true,
  stripe_payment_method_id: "pm_test_4242424242424242"
)

puts "Created #{PaymentMethod.count} payment methods"

puts "Creating coffee preferences..."

CoffeePreference.create!(
  user: robert,
  roast_level: :medium_roast,
  grind_type: :whole_bean
)

CoffeePreference.create!(
  user: customer2,
  roast_level: :light,
  grind_type: :medium_grind
)

puts "Created #{CoffeePreference.count} coffee preferences"

puts "✅ Seed data created successfully!"
puts ""
puts "Test accounts:"
puts "  Admin: admin@coffeeco.com / password123"
puts "  Robert: rpdecks@gmail.com / seedpass"
puts "  Jane: jane@example.com / password123"
