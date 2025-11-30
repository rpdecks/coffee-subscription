class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :subscription_plan
  belongs_to :shipping_address, class_name: "Address", optional: true
  belongs_to :payment_method, optional: true

  has_many :orders

  enum :status, { active: 0, paused: 1, cancelled: 2, past_due: 3 }

  validates :status, presence: true

  scope :active_subscriptions, -> { where(status: :active) }
  scope :due_for_delivery, -> { active_subscriptions.where("next_delivery_date <= ?", Date.today) }

  def pause!
    update(status: :paused)
  end

  def resume!
    update(status: :active) if paused?
  end

  def cancel!
    update(status: :cancelled)
  end

  def calculate_next_delivery_date
    return unless active? && subscription_plan
    (next_delivery_date || Date.today) + subscription_plan.frequency_in_days.days
  end
end
