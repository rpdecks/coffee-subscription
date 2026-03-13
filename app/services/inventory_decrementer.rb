# frozen_string_literal: true

class InventoryDecrementer
  def self.call(product:, quantity:)
    new(product:, quantity:).call
  end

  def initialize(product:, quantity:)
    @product = product
    @quantity = quantity.to_i
  end

  def call
    raise "Quantity must be greater than 0" unless quantity.positive?

    if product.coffee?
      decrement_packaged_inventory!
    else
      decrement_merch_inventory!
    end
  end

  private

  attr_reader :product, :quantity

  def decrement_packaged_inventory!
    raise "Coffee bag size must be configured before recording a sale" unless product.weight_oz.to_f.positive?

    pounds_to_decrement = (product.weight_oz.to_d * quantity) / 16
    packaged_items = product.inventory_items.packaged.available.order(:roasted_on, :created_at)
    remaining = pounds_to_decrement

    if packaged_items.sum(:quantity).to_d < pounds_to_decrement
      raise "Not enough packaged inventory available to record this sale"
    end

    packaged_items.each do |item|
      break if remaining <= 0

      current_quantity = item.quantity.to_d
      deduction = [ current_quantity, remaining ].min
      item.update!(quantity: current_quantity - deduction)
      remaining -= deduction
    end
  end

  def decrement_merch_inventory!
    return if product.inventory_count.nil?
    raise "Not enough inventory available to record this sale" if product.inventory_count < quantity

    product.update!(inventory_count: product.inventory_count - quantity)
  end
end