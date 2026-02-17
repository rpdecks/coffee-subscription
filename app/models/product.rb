class Product < ApplicationRecord
  has_one_attached :image
  has_many_attached :images
  has_many :inventory_items, dependent: :destroy
  has_many :order_items, dependent: :restrict_with_error
  has_many :blend_components, dependent: :destroy
  has_many :green_coffees, through: :blend_components

  after_commit :ensure_image_order_and_featured, on: [ :create, :update ]

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

  def image_attachments
    attachments = []
    attachments << image.attachment if image.attached?
    attachments.concat(images.attachments) if images.attached?
    attachments.compact
  end

  def ordered_image_attachments
    attachments = image_attachments
    return attachments if attachments.empty?

    order = Array(image_attachment_ids_order).map(&:to_i)
    return attachments if order.empty?

    by_id = attachments.index_by(&:id)
    ordered = order.filter_map { |id| by_id[id] }
    remaining = attachments.reject { |a| order.include?(a.id) }
    ordered + remaining
  end

  def featured_image_attachment
    return nil if featured_image_attachment_id.blank?
    image_attachments.find { |a| a.id == featured_image_attachment_id.to_i }
  end

  def carousel_images
    ordered_image_attachments
  end

  private

  def ensure_image_order_and_featured
    attachments = image_attachments
    if attachments.empty?
      update_column(:featured_image_attachment_id, nil) if featured_image_attachment_id.present?
      update_column(:image_attachment_ids_order, []) unless image_attachment_ids_order == []
      return
    end

    existing_ids = attachments.map(&:id)
    order = Array(image_attachment_ids_order).map(&:to_i)

    # Remove IDs that no longer exist, and append any new attachments.
    order &= existing_ids
    order += (existing_ids - order)

    desired_featured_id = order.first

    updates = {}
    updates[:image_attachment_ids_order] = order if order != Array(image_attachment_ids_order).map(&:to_i)
    updates[:featured_image_attachment_id] = desired_featured_id if featured_image_attachment_id.to_i != desired_featured_id.to_i

    return if updates.empty?
    update_columns(updates)
  end
end
