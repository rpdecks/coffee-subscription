class GreenCoffee < ApplicationRecord
  belongs_to :supplier
  has_many :blend_components, dependent: :destroy
  has_many :products, through: :blend_components

  validates :name, presence: true
  validates :quantity_lbs, numericality: { greater_than_or_equal_to: 0 }
  validates :cost_per_lb, numericality: { greater_than: 0 }, allow_nil: true

  scope :in_stock, -> { where("quantity_lbs > 0") }
  scope :out_of_stock, -> { where(quantity_lbs: 0) }
  scope :by_supplier, ->(supplier_id) { where(supplier_id: supplier_id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_arrival, -> { order(arrived_on: :desc) }

  # Freshness thresholds (months since harvest)
  FRESH_MONTHS = 6
  GOOD_MONTHS = 10
  PAST_CROP_MONTHS = 12

  def to_s
    name
  end

  def months_since_harvest
    return nil unless harvest_date
    ((Date.today - harvest_date) / 30.0).round(1)
  end

  def days_since_arrival
    return nil unless arrived_on
    (Date.today - arrived_on).to_i
  end

  def freshness_status
    months = months_since_harvest
    return "unknown" unless months

    if months < FRESH_MONTHS
      "fresh"
    elsif months < GOOD_MONTHS
      "good"
    elsif months < PAST_CROP_MONTHS
      "aging"
    else
      "past_crop"
    end
  end

  def fresh?
    freshness_status == "fresh"
  end

  def past_crop?
    freshness_status == "past_crop"
  end

  def total_cost
    return nil unless cost_per_lb
    cost_per_lb * quantity_lbs
  end

  def display_origin
    [ origin_country, region ].compact_blank.join(", ")
  end

  def display_details
    [ variety, process ].compact_blank.join(" / ")
  end
end
