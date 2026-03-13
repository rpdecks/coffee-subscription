require 'rails_helper'

RSpec.describe "Admin::CustomerReviews", type: :request do
  let(:admin) { create(:admin_user) }
  let(:product) { create(:product) }

  before do
    sign_in admin, scope: :user
  end

  describe "GET /admin/customer_reviews" do
    it "renders successfully" do
      get admin_customer_reviews_path

      expect(response).to have_http_status(:success)
    end

    it "filters to general testimonials" do
      general_review = create(:customer_review, :general, customer_name: "General Person")
      create(:customer_review, product: product, customer_name: "Product Person")

      get admin_customer_reviews_path, params: { product_id: 'general' }

      expect(response.body).to include(general_review.customer_name)
      expect(response.body).not_to include("Product Person")
    end
  end

  describe "POST /admin/customer_reviews" do
    it "creates a general testimonial" do
      expect {
        post admin_customer_reviews_path, params: {
          customer_review: {
            product_id: '',
            customer_name: 'Casey',
            location: 'Bend, OR',
            headline: 'Great service',
            body: 'The coffee is great and the overall experience is even better.',
            rating: 5,
            approved: '1',
            featured_on_about: '1',
            sort_position: 2
          }
        }
      }.to change(CustomerReview, :count).by(1)

      review = CustomerReview.last
      expect(review.product).to be_nil
      expect(review).to be_approved
      expect(review).to be_featured_on_about
      expect(response).to redirect_to(admin_customer_reviews_path)
    end
  end

  describe "PATCH /admin/customer_reviews/:id/toggle_about_featured" do
    it "approves a pending review when featuring it on the about page" do
      review = create(:customer_review, product: product, approved: false, featured_on_about: false)

      patch toggle_about_featured_admin_customer_review_path(review)

      expect(response).to redirect_to(admin_customer_reviews_path)
      expect(review.reload).to be_approved
      expect(review).to be_featured_on_about
    end
  end
end