require 'rails_helper'

RSpec.describe CustomerReview, type: :model do
  describe 'validations' do
    it 'requires a customer name' do
      review = build(:customer_review, customer_name: nil)

      expect(review).not_to be_valid
      expect(review.errors[:customer_name]).to include("can't be blank")
    end

    it 'requires a review body' do
      review = build(:customer_review, body: nil)

      expect(review).not_to be_valid
      expect(review.errors[:body]).to include("can't be blank")
    end

    it 'restricts ratings to the 1..5 range' do
      review = build(:customer_review, rating: 6)

      expect(review).not_to be_valid
      expect(review.errors[:rating]).to include('is not included in the list')
    end
  end

  describe 'callbacks' do
    it 'clears about-page highlighting when a review is not approved' do
      review = create(:customer_review, :approved, featured_on_about: true)

      review.update!(approved: false)

      expect(review.reload.featured_on_about).to be(false)
    end
  end

  describe '#general_testimonial?' do
    it 'returns true when the review is not tied to a product' do
      expect(build(:customer_review, :general)).to be_general_testimonial
    end

    it 'returns false when the review belongs to a product' do
      expect(build(:customer_review)).not_to be_general_testimonial
    end
  end
end