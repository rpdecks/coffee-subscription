class Order < ApplicationRecord
  belongs_to :user
  belongs_to :subscription, optional: true
  belongs_to :shipping_address, class_name: "Address", foreign_key: "shipping_address_id"
  belongs_to :payment_method, optional: true

  has_many :order_items, dependent: :destroy

  enum order_type: { subscription: 0, one_time: 1 }
  enum status: { pending: 0, processing: 1, roasting: 2, shipped: 3, delivered: 4, cancelled: 5 }

  validates :order_number, :order_type, :status, presence: true
  validates :order_number, uniqueness: true

  before_validation :generate_order_number, on: :create

  scope :recent, -> { order(created_at: :desc) }
  scope :pending_fulfillment, -> { where(status: [:pending, :processing, :roasting]) }

  def total
    total_cents / 100.0
  end

  def subtotal
    subtotal_cents / 100.0
  end

  def calculate_totals
    self.subtotal_cents = order_items.sum(&:total_cents)
    self.shipping_cents ||= 0
    self.tax_cents ||= 0
    self.total_cents = subtotal_cents + shipping_cents + tax_cents
  end

  private

  def generate_order_number
    self.order_number = "ORD-#{Time.current.to_i}-#{SecureRandom.hex(3).upcase}"
  end
end
