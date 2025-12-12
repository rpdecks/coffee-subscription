# Example: Seeding Inventory Items
# This shows how to create sample inventory for testing

# Find or create a coffee product (example)
ethiopian_coffee = Product.find_or_create_by!(name: "Ethiopia Yirgacheffe") do |p|
  p.product_type = :coffee
  p.roast_type = :light
  p.price_cents = 1800
  p.description = "Bright, floral, with notes of jasmine and citrus"
  p.active = true
  p.visible_in_shop = true
end

# Add green coffee inventory
InventoryItem.create!([
  {
    product: ethiopian_coffee,
    state: :green,
    quantity: 50.0,
    lot_number: "LOT2024-ETH-001",
    received_on: 2.weeks.ago.to_date,
    notes: "Direct trade, natural process, arrived from Addis Ababa"
  },
  {
    product: ethiopian_coffee,
    state: :roasted,
    quantity: 12.5,
    lot_number: "LOT2024-ETH-001",
    roasted_on: 5.days.ago.to_date,
    expires_on: 16.days.from_now.to_date,
    notes: "Roasted to City+ level, first crack at 9:20"
  },
  {
    product: ethiopian_coffee,
    state: :packaged,
    quantity: 8.0,
    lot_number: "LOT2024-ETH-001",
    roasted_on: 7.days.ago.to_date,
    notes: "Packaged in 12oz bags, ready for shipping"
  }
])

# Example merchandise inventory
mug_product = Product.find_or_create_by!(name: "Acer Coffee Mug") do |p|
  p.product_type = :merch
  p.price_cents = 1500
  p.description = "Beautiful ceramic mug with Acer logo"
  p.active = true
  p.visible_in_shop = true
end

InventoryItem.create!(
  product: mug_product,
  state: :packaged,
  quantity: 25.0,
  received_on: 1.month.ago.to_date,
  notes: "Ceramic mugs, 12oz capacity"
)

puts "✅ Inventory items created successfully!"
puts "   - #{InventoryItem.count} total inventory items"
puts "   - #{InventoryItem.green.count} green coffee items"
puts "   - #{InventoryItem.roasted.count} roasted coffee items"
puts "   - #{InventoryItem.packaged.count} packaged items"
