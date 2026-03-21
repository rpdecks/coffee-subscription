# frozen_string_literal: true

require "json"

payload = JSON.parse(ARGV.fetch(0), symbolize_names: true)
result = RoastAndPackageInventoryRecorder.call(params: payload)
routes = Rails.application.routes.url_helpers

output = {
  success: result.success?,
  errors: result.errors,
  product: result.product && {
    id: result.product.id,
    name: result.product.name,
    admin_path: routes.admin_product_path(result.product),
    total_green_inventory: result.product.total_green_inventory.to_f,
    total_roasted_inventory: result.product.total_roasted_inventory.to_f,
    total_packaged_inventory: result.product.total_packaged_inventory.to_f,
    sellable_bag_count: result.product.sellable_bag_count
  },
  green_coffee: result.green_coffee && {
    id: result.green_coffee.id,
    name: result.green_coffee.name,
    quantity_lbs: result.green_coffee.quantity_lbs.to_f,
    debited_lbs: result.green_coffee_debited_lbs.to_f
  },
  roasted_item: result.roasted_item && {
    id: result.roasted_item.id,
    quantity: result.roasted_item.quantity.to_f,
    roasted_on: result.roasted_item.roasted_on,
    lot_number: result.roasted_item.lot_number,
    batch_id: result.roasted_item.batch_id
  },
  packaged_item: result.packaged_item && {
    id: result.packaged_item.id,
    quantity: result.packaged_item.quantity.to_f,
    roasted_on: result.packaged_item.roasted_on,
    lot_number: result.packaged_item.lot_number,
    batch_id: result.packaged_item.batch_id
  },
  roasted_deductions: result.roasted_deductions.map do |deduction|
    {
      inventory_item_id: deduction.inventory_item.id,
      amount_debited: deduction.amount_debited.to_f,
      remaining: deduction.remaining.to_f
    }
  end
}

puts JSON.generate(output)
