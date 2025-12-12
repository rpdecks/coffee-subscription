class InventoryItem < ApplicationRecord
  belongs_to :product

  enum :state, { green: 0, roasted: 1, packaged: 2 }

  validates :quantity, :state, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validate :coffee_specific_validations

  scope :green, -> { where(state: :green) }
  scope :roasted, -> { where(state: :roasted) }
  scope :packaged, -> { where(state: :packaged) }
  scope :available, -> { where("quantity > 0") }
  scope :low_stock, ->(threshold = 5.0) { where("quantity > 0 AND quantity <= ?", threshold) }
  scope :out_of_stock, -> { where(quantity: 0) }
  scope :expiring_soon, ->(days = 14) { where("expires_on IS NOT NULL AND expires_on <= ?", Date.today + days.days) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_received_date, -> { order(received_on: :desc) }
  scope :by_roast_date, -> { order(roasted_on: :desc) }

  # For coffee products only
  def days_since_roast
    return nil unless roasted_on
    (Date.today - roasted_on).to_i
  end

  def days_until_expiry
    return nil unless expires_on
    (expires_on - Date.today).to_i
  end

  def is_fresh?
    return true unless roasted_on  # Green coffee or non-roasted items
    days_since_roast <= 21  # Coffee is typically fresh for 3 weeks
  end

  def is_expiring_soon?
    return false unless expires_on
    days_until_expiry && days_until_expiry <= 14
  end

  def display_name
    parts = [ product.name ]
    parts << "(#{state.titleize})" if product.coffee?
    parts << "Lot: #{lot_number}" if lot_number.present?
    parts.join(" ")
  end

  private

  def coffee_specific_validations
    return unless product&.coffee?

    if roasted? && roasted_on.blank?
      errors.add(:roasted_on, "must be present for roasted coffee")
    end

    if green? && received_on.blank?
      errors.add(:received_on, "should be present for green coffee")
    end
  end
end
