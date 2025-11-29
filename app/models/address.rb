class Address < ApplicationRecord
  belongs_to :user

  enum address_type: { shipping: 0, billing: 1 }

  validates :street_address, :city, :state, :zip_code, :country, presence: true
  validates :address_type, presence: true

  before_validation :set_default_if_first
  before_save :ensure_only_one_default, if: :is_default?

  scope :default, -> { where(is_default: true) }
  scope :shipping, -> { where(address_type: :shipping) }
  scope :billing, -> { where(address_type: :billing) }

  def full_address
    [
      street_address,
      street_address_2,
      "#{city}, #{state} #{zip_code}",
      country
    ].compact.reject(&:blank?).join("\n")
  end

  private

  def set_default_if_first
    # If this is the first address of this type for the user, make it default
    if user && user.addresses.where(address_type: address_type).where.not(id: id).empty?
      self.is_default = true
    end
  end

  def ensure_only_one_default
    # Ensure only one address per type is marked as default
    user.addresses.where(address_type: address_type, is_default: true)
        .where.not(id: id).update_all(is_default: false)
  end
end
