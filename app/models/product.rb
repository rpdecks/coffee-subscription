class Product < ApplicationRecord
  enum :product_type, { coffee: 0, merch: 1 }

  validates :name, :price_cents, presence: true
  validates :price_cents, numericality: { greater_than: 0 }
  validates :inventory_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :coffee, -> { where(product_type: :coffee) }
  scope :merch, -> { where(product_type: :merch) }
  scope :in_stock, -> { where("inventory_count IS NULL OR inventory_count > 0") }

  def price
    price_cents / 100.0
  end

  def price=(dollars)
    self.price_cents = (dollars.to_f * 100).round
  end

  def in_stock?
    inventory_count.nil? || inventory_count > 0
  end
end
