class Product < ApplicationRecord
  has_one_attached :image
  has_many_attached :images
  has_many :inventory_items, dependent: :destroy

  enum :product_type, { coffee: 0, merch: 1 }
  enum :roast_type, { signature: 0, light: 1, medium: 2, dark: 3 }

  validates :name, :price_cents, presence: true
  validates :price_cents, numericality: { greater_than: 0 }
  validates :inventory_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :visible_in_shop, -> { where(visible_in_shop: true) }
  scope :coffee, -> { where(product_type: :coffee) }
  scope :merch, -> { where(product_type: :merch) }
  scope :in_stock, -> { where("inventory_count IS NULL OR inventory_count > 0") }

  def price
    return 0.0 if price_cents.nil?
    price_cents / 100.0
  end

  def price=(dollars)
    self.price_cents = (dollars.to_f * 100).round
  end

  def in_stock?
    inventory_count.nil? || inventory_count > 0
  end

  # New inventory management methods
  def total_green_inventory
    return 0.0 unless coffee?
    inventory_items.green.sum(:quantity)
  end

  def total_roasted_inventory
    return 0.0 unless coffee?
    inventory_items.roasted.sum(:quantity)
  end

  def total_packaged_inventory
    inventory_items.packaged.sum(:quantity)
  end

  def total_inventory_pounds
    if coffee?
      total_green_inventory + total_roasted_inventory + total_packaged_inventory
    else
      inventory_items.sum(:quantity)
    end
  end

  def low_on_inventory?(threshold = 5.0)
    total_inventory_pounds < threshold
  end

  def fresh_roasted_inventory
    return 0.0 unless coffee?
    inventory_items.roasted.select(&:is_fresh?).sum(&:quantity)
  end

  def cultivar_icon
    return nil unless coffee?
    case roast_type&.to_sym
    when :signature then "brand/cultivar-icons/palmatum.png"
    when :light then "brand/cultivar-icons/deshojo.svg"
    when :medium then "brand/cultivar-icons/arakawa.svg"
    when :dark then "brand/cultivar-icons/kiyohime.svg"
    else "brand/cultivar-icons/palmatum.png"
    end
  end

  def cultivar_color
    return "text-cream" unless coffee?
    case roast_type&.to_sym
    when :signature then "text-cream"
    when :light then "text-deshojo"
    when :medium then "text-coffee-brown"
    when :dark then "text-coffee-brown"
    else "text-cream"
    end
  end
end
