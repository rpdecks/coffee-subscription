class PaymentMethod < ApplicationRecord
  belongs_to :user

  validates :stripe_payment_method_id, :card_brand, :last_four, presence: true
  validates :exp_month, :exp_year, presence: true, numericality: { only_integer: true }

  before_save :ensure_only_one_default, if: :is_default?

  scope :default, -> { where(is_default: true) }

  def display_name
    "#{card_brand} ending in #{last_four}"
  end

  def expired?
    Date.new(exp_year, exp_month, -1) < Date.today
  end

  private

  def ensure_only_one_default
    user.payment_methods.where(is_default: true)
        .where.not(id: id).update_all(is_default: false)
  end
end
