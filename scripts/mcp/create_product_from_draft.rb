# frozen_string_literal: true

require "json"

payload = JSON.parse(ARGV.fetch(0), symbolize_names: true)
result = ProductDraftCreator.call(params: payload)
product = result.product
routes = Rails.application.routes.url_helpers

output = {
  success: result.success?,
  errors: result.errors,
  product: product && {
    id: product.id,
    name: product.name,
    admin_path: routes.admin_product_path(product),
    product_type: product.product_type,
    roast_type: product.roast_type,
    price_cents: product.price_cents,
    weight_oz: product.weight_oz&.to_f,
    inventory_count: product.inventory_count,
    active: product.active,
    visible_in_shop: product.visible_in_shop
  }
}

puts JSON.generate(output)
