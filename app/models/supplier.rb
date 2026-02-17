class Supplier < ApplicationRecord
  has_many :green_coffees, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  scope :alphabetical, -> { order(:name) }

  def to_s
    name
  end

  # Returns URL only if it uses a safe protocol, nil otherwise.
  # This satisfies Brakeman's LinkToHref check.
  def safe_url
    url.presence&.match?(%r{\Ahttps?://}) ? url : nil
  end

  def green_coffee_count
    green_coffees.count
  end

  def total_green_inventory_lbs
    green_coffees.sum(:quantity_lbs)
  end

  def total_spend
    green_coffees.sum("cost_per_lb * quantity_lbs")
  end
end
