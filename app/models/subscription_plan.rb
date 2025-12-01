class SubscriptionPlan < ApplicationRecord
  enum :frequency, { weekly: 0, biweekly: 1, monthly: 2 }

  has_many :subscriptions

  validates :name, :frequency, :bags_per_delivery, :price_cents, presence: true
  validates :price_cents, numericality: { greater_than: 0 }
  validates :bags_per_delivery, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }

  def price
    return 0.0 if price_cents.nil?
    price_cents / 100.0
  end

  def price=(dollars)
    self.price_cents = (dollars.to_f * 100).round
  end

  def frequency_in_days
    case frequency
    when "weekly" then 7
    when "biweekly" then 14
    when "monthly" then 30
    end
  end

  def name_with_frequency
    "#{name} (#{frequency.titleize})"
  end
end
