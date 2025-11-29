class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  enum grind_type: { whole_bean: 0, coarse: 1, medium_grind: 2, fine: 3, espresso: 4 }

  validates :quantity, :price_cents, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :price_cents, numericality: { greater_than: 0 }

  before_validation :set_price_from_product, on: :create

  def total_cents
    quantity * price_cents
  end

  def total
    total_cents / 100.0
  end

  def price
    price_cents / 100.0
  end

  private

  def set_price_from_product
    self.price_cents ||= product&.price_cents
  end
end
