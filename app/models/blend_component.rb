class BlendComponent < ApplicationRecord
  belongs_to :product
  belongs_to :green_coffee

  validates :percentage, presence: true,
    numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :green_coffee_id, uniqueness: { scope: :product_id,
    message: "is already part of this blend" }

  validate :total_percentage_not_over_100

  scope :by_percentage, -> { order(percentage: :desc) }

  def to_s
    "#{green_coffee.name} (#{percentage}%)"
  end

  private

  def total_percentage_not_over_100
    return unless product && percentage

    other_total = product.blend_components
      .where.not(id: id)
      .sum(:percentage)

    if other_total + percentage > 100
      errors.add(:percentage, "total cannot exceed 100% (currently #{other_total}% allocated)")
    end
  end
end
