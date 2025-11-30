class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Role enum
  enum :role, { customer: 0, admin: 1 }

  # Validations
  validates :first_name, :last_name, presence: true
  validates :phone, format: { with: /\A[\d\s\-\(\)\+]+\z/, message: "must be a valid phone number" }, allow_blank: true

  # Associations
  has_many :addresses, dependent: :destroy
  has_many :payment_methods, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_one :coffee_preference, dependent: :destroy

  def full_name
    "#{first_name} #{last_name}".strip
  end
end
