# This file seeds safe baseline data in every environment and richer preview/demo
# data in staging and development. Use SEED_RESET=1 for a destructive reset.

ADMIN_PASSWORD = ENV.fetch("SEED_ADMIN_PASSWORD", "ChangeMe123!")
CUSTOMER_PASSWORD = ENV.fetch("SEED_CUSTOMER_PASSWORD", "TestPass123!")
RESET_SEED = ActiveModel::Type::Boolean.new.cast(ENV["DEMO_SEED"] || ENV["SEED_RESET"])
PREVIEW_ENV = Rails.env.development? || Rails.env.staging?

def confirm_production_reset!
  return unless Rails.env.production?
  return if RESET_SEED

  puts "Production seeding is disabled unless SEED_RESET=1 is set."
  exit 1
end

def confirm_destructive_seed!
  return unless RESET_SEED
  return unless Rails.env.production?

  puts "\n" + ("=" * 80)
  puts "WARNING: You are about to reset the PRODUCTION database with demo data!"
  puts ("=" * 80)
  print "\nType 'DELETE ALL PRODUCTION DATA' (exactly) to continue: "

  confirmation = STDIN.gets&.chomp

  unless confirmation == "DELETE ALL PRODUCTION DATA"
    puts "\nSeeding cancelled."
    exit 0
  end
end

def seed_subscription_plans!
  [
    {
      name: "Weekly - 1 Bag",
      description: "One 12oz bag delivered every week. Perfect for daily coffee drinkers.",
      frequency: :weekly,
      bags_per_delivery: 1,
      price_cents: 1800,
      active: true
    },
    {
      name: "Weekly - 2 Bags",
      description: "Two 12oz bags delivered every week. Ideal for households that go through coffee fast.",
      frequency: :weekly,
      bags_per_delivery: 2,
      price_cents: 3400,
      active: true
    },
    {
      name: "Bi-Weekly - 1 Bag",
      description: "One 12oz bag delivered every two weeks. Great if you brew a few times a week.",
      frequency: :biweekly,
      bags_per_delivery: 1,
      price_cents: 1700,
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
      name: "Monthly - 1 Bag",
      description: "One 12oz bag delivered monthly. Easy way to keep your shelf stocked.",
      frequency: :monthly,
      bags_per_delivery: 1,
      price_cents: 1600,
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
    },
    {
      name: "Legacy Plan",
      description: "Old plan no longer offered to new customers.",
      frequency: :monthly,
      bags_per_delivery: 1,
      price_cents: 1500,
      active: false
    }
  ].each do |attrs|
    plan = SubscriptionPlan.find_or_initialize_by(name: attrs[:name])
    plan.assign_attributes(attrs)
    plan.save!
  end
end

def create_or_update_user!(attrs, password:, role: :customer)
  user = User.find_or_initialize_by(email: attrs[:email])
  user.first_name = attrs[:first_name]
  user.last_name = attrs[:last_name]
  user.phone = attrs[:phone]
  user.role = role

  if user.new_record? || user.encrypted_password.blank?
    user.password = password
    user.password_confirmation = password
  end

  user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
  user.save!
  user
end

def seed_admin_users!
  [
    { email: "rp@acercoffee.com", first_name: "Robert", last_name: "Phillips", phone: "555-234-5678" },
    { email: "kp@acercoffee.com", first_name: "Katie", last_name: "Phillips", phone: "555-234-5679" },
    { email: "admin@acercoffee.com", first_name: "Acer", last_name: "Admin", phone: "555-234-5680" }
  ].map do |attrs|
    create_or_update_user!(attrs, password: ADMIN_PASSWORD, role: :admin)
  end
end

def seed_customers!
  [
    { email: "test1@example.com", first_name: "Emma", last_name: "Johnson", phone: "555-100-0001" },
    { email: "test2@example.com", first_name: "Liam", last_name: "Williams", phone: "555-100-0002" },
    { email: "test3@example.com", first_name: "Olivia", last_name: "Brown", phone: "555-100-0003" }
  ].map do |attrs|
    create_or_update_user!(attrs, password: CUSTOMER_PASSWORD, role: :customer)
  end
end

def find_or_create_address!(user, attrs)
  address = user.addresses.find_or_initialize_by(
    address_type: attrs[:address_type],
    street_address: attrs[:street_address],
    city: attrs[:city],
    state: attrs[:state],
    zip_code: attrs[:zip_code],
    country: attrs[:country]
  )
  address.street_address_2 = attrs[:street_address_2]
  address.is_default = attrs.fetch(:is_default, true)
  address.save!
  address
end

def seed_addresses!(users)
  address_book = {
    "rp@acercoffee.com" => { address_type: :shipping, street_address: "123 Maple St", city: "Knoxville", state: "TN", zip_code: "37902", country: "US", is_default: true },
    "kp@acercoffee.com" => { address_type: :shipping, street_address: "456 Walnut Ave", city: "Knoxville", state: "TN", zip_code: "37902", country: "US", is_default: true },
    "admin@acercoffee.com" => { address_type: :shipping, street_address: "789 Roaster Rd", city: "Knoxville", state: "TN", zip_code: "37920", country: "US", is_default: true },
    "test1@example.com" => { address_type: :shipping, street_address: "45 Market St", city: "Irmo", state: "SC", zip_code: "29063", country: "US", is_default: true },
    "test2@example.com" => { address_type: :shipping, street_address: "88 River Dr", city: "Columbia", state: "SC", zip_code: "29201", country: "US", is_default: true },
    "test3@example.com" => { address_type: :shipping, street_address: "19 Oak Leaf Ln", city: "Lexington", state: "SC", zip_code: "29072", country: "US", is_default: true }
  }

  users.index_with do |user|
    find_or_create_address!(user, address_book.fetch(user.email))
  end
end

def seed_payment_methods!(users)
  users.each_with_index do |user, index|
    payment_method = user.payment_methods.find_or_initialize_by(stripe_payment_method_id: "pm_seed_#{index + 1}")
    payment_method.card_brand = ["Visa", "Mastercard", "Amex"][index % 3]
    payment_method.last_four = format("%04d", 4242 + index)
    payment_method.exp_month = 12
    payment_method.exp_year = 2029
    payment_method.is_default = true
    payment_method.save!
  end
end

def seed_coffee_preferences!(users)
  preferences = {
    "test1@example.com" => { roast_level: :medium_roast, grind_type: :whole_bean },
    "test2@example.com" => { roast_level: :light, grind_type: :medium_grind },
    "test3@example.com" => { roast_level: :dark, grind_type: :espresso }
  }

  users.each do |user|
    attrs = preferences[user.email]
    next unless attrs

    preference = user.coffee_preference || user.build_coffee_preference
    preference.assign_attributes(attrs)
    preference.save!
  end
end

def seed_suppliers!
  [
    { name: "Genuine Origin", contact_email: "sales@genuineorigin.com", contact_name: "Origin Team", url: "https://www.genuineorigin.com" },
    { name: "Cafe Imports", contact_email: "hello@cafeimports.com", contact_name: "Imports Team", url: "https://www.cafeimports.com" }
  ].map do |attrs|
    supplier = Supplier.find_or_initialize_by(name: attrs[:name])
    supplier.assign_attributes(attrs)
    supplier.save!
    supplier
  end
end

def attach_seed_fact_sheet!(green_coffee)
  return if green_coffee.fact_sheet.attached?

  green_coffee.fact_sheet.attach(
    io: StringIO.new("%PDF-1.4\n1 0 obj\n<< /Type /Catalog >>\nendobj\ntrailer\n<< /Root 1 0 R >>\n%%EOF\n"),
    filename: "#{green_coffee.name.parameterize}-fact-sheet.pdf",
    content_type: "application/pdf"
  )
end

def seed_green_coffees!(suppliers)
  supplier_map = suppliers.index_by(&:name)
  [
    {
      supplier: "Genuine Origin",
      name: "Guatemala Huehuetenango",
      origin_country: "Guatemala",
      region: "Huehuetenango",
      variety: "Bourbon / Caturra",
      process: "Washed",
      harvest_date: Date.new(2025, 11, 1),
      arrived_on: Date.new(2026, 2, 10),
      cost_per_lb: 5.85,
      quantity_lbs: 120.0,
      lot_number: "GUA-2025-01",
      notes: "Chocolate-forward base coffee for Palmatum and Arakawa."
    },
    {
      supplier: "Genuine Origin",
      name: "Costa Rica Tarrazu",
      origin_country: "Costa Rica",
      region: "Tarrazu",
      variety: "Catuai",
      process: "Honey",
      harvest_date: Date.new(2025, 10, 15),
      arrived_on: Date.new(2026, 2, 10),
      cost_per_lb: 6.1,
      quantity_lbs: 95.0,
      lot_number: "CRC-2025-02",
      notes: "Adds syrupy sweetness and structure."
    },
    {
      supplier: "Cafe Imports",
      name: "Ethiopia Sidama",
      origin_country: "Ethiopia",
      region: "Sidama",
      variety: "Heirloom",
      process: "Washed",
      harvest_date: Date.new(2025, 12, 1),
      arrived_on: Date.new(2026, 2, 22),
      cost_per_lb: 6.75,
      quantity_lbs: 70.0,
      lot_number: "ETH-2025-03",
      notes: "Floral top note coffee for Deshojo."
    }
  ].map do |attrs|
    supplier = supplier_map.fetch(attrs.delete(:supplier))
    green_coffee = GreenCoffee.find_or_initialize_by(name: attrs[:name])
    green_coffee.supplier = supplier
    green_coffee.assign_attributes(attrs)
    green_coffee.save!
    attach_seed_fact_sheet!(green_coffee)
    green_coffee
  end
end

def seed_products!
  [
    {
      name: "Palmatum Blend",
      description: "A syrupy, bittersweet espresso-forward coffee with dark chocolate, toasted almond, and citrus peel.",
      product_type: :coffee,
      roast_type: :signature,
      price_cents: 1500,
      weight_oz: 12,
      inventory_count: 40,
      active: true,
      visible_in_shop: true
    },
    {
      name: "Deshojo Blend",
      description: "A vivid, fruit-forward roast with dark cherry, cocoa, and cedar.",
      product_type: :coffee,
      roast_type: :light,
      price_cents: 1700,
      weight_oz: 12,
      inventory_count: 24,
      active: true,
      visible_in_shop: true
    },
    {
      name: "Arakawa Blend",
      description: "Balanced and versatile with caramel sweetness and a structured finish.",
      product_type: :coffee,
      roast_type: :medium,
      price_cents: 1600,
      weight_oz: 12,
      inventory_count: 18,
      active: true,
      visible_in_shop: true
    },
    {
      name: "Acer Coffee Mug",
      description: "Ceramic mug with Acer Coffee branding.",
      product_type: :merch,
      price_cents: 1200,
      inventory_count: 24,
      active: true,
      visible_in_shop: true
    },
    {
      name: "Acer Coffee T-Shirt",
      description: "Cotton t-shirt with Acer Coffee logo.",
      product_type: :merch,
      price_cents: 2400,
      inventory_count: 18,
      active: true,
      visible_in_shop: true
    }
  ].map do |attrs|
    product = Product.find_or_initialize_by(name: attrs[:name])
    product.assign_attributes(attrs)
    product.save!
    product
  end
end

def seed_product_images!(products)
  image_map = {
    "Palmatum Blend" => "app/assets/images/products/palmatum.jpeg",
    "Deshojo Blend" => "app/assets/images/products/palmatum_03.jpg"
  }

  products.each do |product|
    image_path = image_map[product.name]
    next if image_path.blank?
    next unless File.exist?(Rails.root.join(image_path))
    next if product.image.attached?

    product.image.attach(
      io: File.open(Rails.root.join(image_path)),
      filename: File.basename(image_path),
      content_type: "image/jpeg"
    )
  end
end

def seed_blend_components!(products, green_coffees)
  product_map = products.index_by(&:name)
  green_map = green_coffees.index_by(&:name)

  {
    "Palmatum Blend" => {
      "Guatemala Huehuetenango" => 55,
      "Costa Rica Tarrazu" => 45
    },
    "Deshojo Blend" => {
      "Ethiopia Sidama" => 100
    },
    "Arakawa Blend" => {
      "Guatemala Huehuetenango" => 60,
      "Costa Rica Tarrazu" => 40
    }
  }.each do |product_name, components|
    product = product_map.fetch(product_name)

    components.each do |green_name, percentage|
      component = BlendComponent.find_or_initialize_by(product: product, green_coffee: green_map.fetch(green_name))
      component.percentage = percentage
      component.save!
    end
  end
end

def seed_inventory_items!(products)
  product_map = products.index_by(&:name)

  inventory_rows = [
    { product: "Palmatum Blend", state: :green, quantity: 11.70, lot_number: "PAL-2026-02-16g", received_on: Date.new(2026, 2, 10) },
    { product: "Palmatum Blend", state: :roasted, quantity: 0.95, lot_number: "PAL-2026-02-16a", roasted_on: Date.new(2026, 2, 16), expires_on: Date.new(2026, 3, 17) },
    { product: "Palmatum Blend", state: :packaged, quantity: 0.97, lot_number: "PAL-2026-02-16b", roasted_on: Date.new(2026, 2, 16), expires_on: Date.new(2026, 4, 1) },
    { product: "Palmatum Blend", state: :packaged, quantity: 0.97, lot_number: "PAL-2026-02-16c", roasted_on: Date.new(2026, 2, 16), expires_on: Date.new(2026, 4, 1) },
    { product: "Deshojo Blend", state: :green, quantity: 8.0, lot_number: "DES-2026-02-20g", received_on: Date.new(2026, 2, 22) },
    { product: "Deshojo Blend", state: :packaged, quantity: 1.50, lot_number: "DES-2026-02-24p", roasted_on: Date.new(2026, 2, 24), expires_on: Date.new(2026, 4, 8) },
    { product: "Arakawa Blend", state: :green, quantity: 6.0, lot_number: "ARA-2026-02-18g", received_on: Date.new(2026, 2, 18) },
    { product: "Arakawa Blend", state: :roasted, quantity: 2.0, lot_number: "ARA-2026-02-25r", roasted_on: Date.new(2026, 2, 25), expires_on: Date.new(2026, 4, 10) },
    { product: "Arakawa Blend", state: :packaged, quantity: 2.25, lot_number: "ARA-2026-02-25p", roasted_on: Date.new(2026, 2, 25), expires_on: Date.new(2026, 4, 10) }
  ]

  inventory_rows.each do |attrs|
    product = product_map.fetch(attrs.delete(:product))
    item = InventoryItem.find_or_initialize_by(product: product, lot_number: attrs[:lot_number], state: attrs[:state])
    item.assign_attributes(attrs.merge(product: product))
    item.save!
  end
end

def seed_subscriptions!(customers, addresses)
  plans = SubscriptionPlan.active.index_by(&:name)

  [
    { email: "test1@example.com", plan: "Weekly - 1 Bag", status: :active, quantity: 1, next_delivery_date: Date.current + 7.days },
    { email: "test2@example.com", plan: "Monthly - 2 Bags", status: :active, quantity: 1, next_delivery_date: Date.current + 14.days },
    { email: "test3@example.com", plan: "Bi-Weekly - 2 Bags", status: :paused, quantity: 1, next_delivery_date: Date.current + 21.days }
  ].map do |attrs|
    user = customers.find { |customer| customer.email == attrs[:email] }
    subscription = Subscription.find_or_initialize_by(user: user, subscription_plan: plans.fetch(attrs[:plan]))
    subscription.assign_attributes(
      status: attrs[:status],
      quantity: attrs[:quantity],
      next_delivery_date: attrs[:next_delivery_date],
      shipping_address: addresses.fetch(user),
      payment_method: user.payment_methods.first
    )
    subscription.save!
    subscription
  end
end

def create_order_with_items!(user:, order_number:, order_type:, status:, shipping_address:, items:, subscription: nil, created_at:, stripe_reference: nil)
  order = Order.find_or_initialize_by(order_number: order_number)
  order.user = user
  order.subscription = subscription
  order.order_type = order_type
  order.status = status
  order.shipping_address = shipping_address
  order.stripe_payment_intent_id = stripe_reference if stripe_reference.present?
  order.created_at = created_at if order.new_record?
  order.shipped_at = created_at + 2.days if status.to_s == "shipped"
  order.delivered_at = created_at + 4.days if status.to_s == "delivered"
  order.save!

  existing_keys = order.order_items.map { |item| [item.product_id, item.quantity] }
  items.each do |item_attrs|
    product = item_attrs.fetch(:product)
    quantity = item_attrs.fetch(:quantity)
    next if existing_keys.include?([product.id, quantity])

    order.order_items.create!(product: product, quantity: quantity, price_cents: product.price_cents)
  end

  order.calculate_totals
  order.shipping_cents ||= 0
  order.tax_cents ||= (order.subtotal_cents * 0.06).round
  order.total_cents = order.subtotal_cents + order.shipping_cents + order.tax_cents
  order.save!
  order
end

def seed_orders!(customers, addresses, subscriptions, products)
  product_map = products.index_by(&:name)
  customer_map = customers.index_by(&:email)
  subscription_map = subscriptions.index_by { |subscription| subscription.user.email }

  create_order_with_items!(
    user: customer_map.fetch("test1@example.com"),
    order_number: "SEED-ORDER-0001",
    order_type: :subscription,
    status: :delivered,
    shipping_address: addresses.fetch(customer_map.fetch("test1@example.com")),
    subscription: subscription_map.fetch("test1@example.com"),
    created_at: 35.days.ago,
    items: [ { product: product_map.fetch("Palmatum Blend"), quantity: 1 } ]
  )

  create_order_with_items!(
    user: customer_map.fetch("test2@example.com"),
    order_number: "SEED-ORDER-0002",
    order_type: :subscription,
    status: :processing,
    shipping_address: addresses.fetch(customer_map.fetch("test2@example.com")),
    subscription: subscription_map.fetch("test2@example.com"),
    created_at: 3.days.ago,
    items: [
      { product: product_map.fetch("Deshojo Blend"), quantity: 1 },
      { product: product_map.fetch("Arakawa Blend"), quantity: 1 }
    ]
  )

  create_order_with_items!(
    user: customer_map.fetch("test3@example.com"),
    order_number: "SEED-ORDER-0003",
    order_type: :one_time,
    status: :delivered,
    shipping_address: addresses.fetch(customer_map.fetch("test3@example.com")),
    created_at: 10.days.ago,
    stripe_reference: "pi_seed_manual_123",
    items: [ { product: product_map.fetch("Acer Coffee Mug"), quantity: 1 } ]
  )
end

def clear_demo_data!
  puts "Clearing existing data..."
  OrderItem.destroy_all
  Order.destroy_all
  Subscription.destroy_all
  PaymentMethod.destroy_all
  CoffeePreference.destroy_all
  InventoryItem.destroy_all
  BlendComponent.destroy_all
  Product.destroy_all
  GreenCoffee.destroy_all
  Supplier.destroy_all
  Address.destroy_all
  User.destroy_all
  SubscriptionPlan.destroy_all
end

def seed_preview_dataset!
  admins = seed_admin_users!
  customers = seed_customers!
  all_users = admins + customers
  addresses = seed_addresses!(all_users)
  seed_payment_methods!(customers)
  seed_coffee_preferences!(customers)
  suppliers = seed_suppliers!
  green_coffees = seed_green_coffees!(suppliers)
  products = seed_products!
  seed_product_images!(products)
  seed_blend_components!(products, green_coffees)
  seed_inventory_items!(products)
  subscriptions = seed_subscriptions!(customers, addresses)
  seed_orders!(customers, addresses, subscriptions, products)
end

def print_seed_summary(preview_seeded:)
  puts "\nSeed data created successfully!"
  puts ""
  puts "=" * 60
  puts "SUMMARY"
  puts "=" * 60
  puts "Users: #{User.count} (#{User.admin.count} admins, #{User.customer.count} customers)"
  puts "Products: #{Product.count} (#{Product.coffee.count} coffee, #{Product.merch.count} merch)"
  puts "Green Coffees: #{GreenCoffee.count}"
  puts "Suppliers: #{Supplier.count}"
  puts "Inventory Items: #{InventoryItem.count}"
  puts "Subscription Plans: #{SubscriptionPlan.count} (#{SubscriptionPlan.active.count} active)"
  puts "Subscriptions: #{Subscription.count} (#{Subscription.where(status: :active).count} active)"
  puts "Orders: #{Order.count}"

  return unless preview_seeded

  puts ""
  puts "TEST ACCOUNTS"
  puts "=" * 60
  puts "Admin Accounts:"
  puts "  - rp@acercoffee.com / #{ADMIN_PASSWORD}"
  puts "  - kp@acercoffee.com / #{ADMIN_PASSWORD}"
  puts "  - admin@acercoffee.com / #{ADMIN_PASSWORD}"
  puts ""
  puts "Sample Customers:"
  puts "  - test1@example.com / #{CUSTOMER_PASSWORD}"
  puts "  - test2@example.com / #{CUSTOMER_PASSWORD}"
  puts "  - test3@example.com / #{CUSTOMER_PASSWORD}"
  puts "=" * 60
end

confirm_production_reset!
confirm_destructive_seed!

clear_demo_data! if RESET_SEED

puts RESET_SEED ? "Running reset seed..." : "Running seed..."
seed_subscription_plans!

if PREVIEW_ENV || RESET_SEED
  seed_preview_dataset!
else
  puts "Seeded subscription plans only."
end

print_seed_summary(preview_seeded: PREVIEW_ENV || RESET_SEED)

unless RESET_SEED
  puts "\nTip: run a full reset seed with SEED_RESET=1 bin/rails db:seed"
end
