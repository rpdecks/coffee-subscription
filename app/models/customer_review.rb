class CustomerReview < ApplicationRecord
  belongs_to :product, optional: true

  before_validation :clear_about_featured_unless_approved

  validates :customer_name, presence: true
  validates :body, presence: true
  validates :rating, inclusion: { in: 1..5 }
  validates :sort_position, numericality: { only_integer: true }

  scope :approved, -> { where(approved: true) }
  scope :pending, -> { where(approved: false) }
  scope :featured_on_about, -> { where(featured_on_about: true) }
  scope :newest_first, -> { order(created_at: :desc) }
  scope :display_order, -> { order(sort_position: :asc, created_at: :desc) }

  def general_testimonial?
    product.blank?
  end

  def display_title
    headline.presence || body.truncate(48)
  end

  private

  def clear_about_featured_unless_approved
    self.featured_on_about = false unless approved?
  end
end
