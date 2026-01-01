class User < ApplicationRecord
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
    devise :database_authenticatable, :registerable,
      :recoverable, :rememberable, :validatable, :confirmable

  def self.serialize_from_session(key, salt = nil)
    if salt.nil? && key.is_a?(Array)
      salt = key[1]
      key = key[0]
    end

    super(key, salt)
  end

  # Role enum
  enum :role, { customer: 0, admin: 1 }

  # Avatar attachment
  has_one_attached :avatar

  # Validations
  validates :first_name, :last_name, presence: true
  validates :phone, format: { with: /\A[\d\s\-\(\)\+]+\z/, message: "must be a valid phone number" }, allow_blank: true
  validate :avatar_file_type, :avatar_file_size, if: -> { avatar.attached? }

  # Associations
  has_many :addresses, dependent: :destroy
  has_many :payment_methods, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_one :coffee_preference, dependent: :destroy

  # Callbacks
  after_create :create_stripe_customer, if: :customer?

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def ensure_stripe_customer
    return stripe_customer_id if stripe_customer_id.present?
    StripeService.create_customer(self)
  end

  private

  def avatar_file_type
    return unless avatar.attached?
    unless avatar.content_type.in?(%w[image/png image/jpeg image/webp])
      errors.add(:avatar, "must be a PNG, JPEG, or WebP image")
    end
  end

  def avatar_file_size
    return unless avatar.attached?
    if avatar.blob.byte_size > 5.megabytes
      errors.add(:avatar, "must be less than 5 MB")
    end
  end

  def create_stripe_customer
    # Create Stripe customer asynchronously to not block signup
    CreateStripeCustomerJob.perform_later(id)
  rescue => e
    Rails.logger.error("Failed to queue Stripe customer creation: #{e.message}")
    # Don't raise - signup should still succeed even if Stripe fails
  end
end
