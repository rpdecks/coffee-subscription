class Order < ApplicationRecord
  ALLOWED_STATUS_TRANSITIONS = {
    "pending" => %w[processing roasting shipped delivered cancelled],
    "processing" => %w[roasting shipped delivered cancelled],
    "roasting" => %w[shipped delivered cancelled],
    "shipped" => %w[delivered cancelled],
    "delivered" => [],
    "cancelled" => []
  }.freeze

  belongs_to :user
  belongs_to :subscription, optional: true
  belongs_to :shipping_address, class_name: "Address", foreign_key: "shipping_address_id"
  belongs_to :payment_method, optional: true

  has_many :order_items, dependent: :destroy

  enum :order_type, { subscription: 0, one_time: 1 }
  enum :status, { pending: 0, processing: 1, roasting: 2, shipped: 3, delivered: 4, cancelled: 5 }

  validates :order_number, :order_type, :status, presence: true
  validates :order_number, uniqueness: true
  validate :status_transition_must_be_allowed, if: :will_save_change_to_status?

  before_validation :generate_order_number, on: :create

  scope :recent, -> { order(created_at: :desc) }
  scope :pending_fulfillment, -> { where(status: [ :pending, :processing, :roasting ]) }
  scope :delivered_today, -> { where(delivered_at: Time.zone.today.all_day) }

  def self.allowed_status_transitions_for(status)
    ALLOWED_STATUS_TRANSITIONS.fetch(status.to_s, [])
  end

  def total
    (total_cents || 0) / 100.0
  end

  def subtotal
    (subtotal_cents || 0) / 100.0
  end

  def shipping
    (shipping_cents || 0) / 100.0
  end

  def tax
    (tax_cents || 0) / 100.0
  end

  def calculate_totals
    self.subtotal_cents = order_items.sum(&:total_cents)
    self.shipping_cents ||= 0
    self.tax_cents ||= 0
    self.total_cents = subtotal_cents + shipping_cents + tax_cents
  end

  def available_statuses_for_admin
    ([ status ] + self.class.allowed_status_transitions_for(status)).uniq
  end

  def pending_fulfillment?
    pending? || processing? || roasting?
  end

  def next_fulfillment_step
    case status
    when "pending"
      "Review payment and move into processing"
    when "processing"
      "Queue roasting and prepare inventory"
    when "roasting"
      "Pack order and finish handoff"
    when "shipped"
      "Waiting for delivery confirmation"
    when "delivered"
      "Completed"
    when "cancelled"
      "Cancelled"
    else
      "Review order"
    end
  end

  private

  def status_transition_must_be_allowed
    previous_status = status_in_database
    return if previous_status.blank? || previous_status == status
    return if self.class.allowed_status_transitions_for(previous_status).include?(status)

    errors.add(:status, "cannot change from #{previous_status.titleize} to #{status.titleize}")
  end

  def generate_order_number
    self.order_number ||= "ORD-#{Time.current.to_i}-#{SecureRandom.hex(3).upcase}"
  end
end
