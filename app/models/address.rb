class Address < ApplicationRecord
  belongs_to :user

  enum address_type: { shipping: 0, billing: 1 }

  validates :street_address, :city, :state, :zip_code, :country, presence: true
  validates :address_type, presence: true

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

  def ensure_only_one_default
    user.addresses.where(address_type: address_type, is_default: true)
        .where.not(id: id).update_all(is_default: false)
  end
end
