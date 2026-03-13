require 'rails_helper'

RSpec.describe "Products", type: :request do
  describe "GET /products" do
    it "returns http success" do
      get products_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /products/:id" do
    it "returns http success" do
      product = FactoryBot.create(:product, active: true)
      get product_path(product)
      expect(response).to have_http_status(:success)
    end

    it "shows approved reviews and hides pending ones" do
      product = create(:product, active: true)
      approved_review = create(:customer_review, :approved, product: product, body: "Bright and sweet")
      create(:customer_review, product: product, body: "Still pending moderation")

      get product_path(product)

      expect(response.body).to include(approved_review.body)
      expect(response.body).not_to include("Still pending moderation")
    end
  end

  describe "POST /products/:product_id/customer_reviews" do
    let(:product) { create(:product, active: true) }

    it "creates a pending review" do
      expect {
        post product_customer_reviews_path(product), params: {
          customer_review: {
            customer_name: "Jordan",
            location: "Salem, OR",
            headline: "Excellent",
            body: "This has become my default morning bag.",
            rating: 5
          }
        }
      }.to change(CustomerReview, :count).by(1)

      review = CustomerReview.last
      expect(review.product).to eq(product)
      expect(review.approved).to be(false)
      expect(response).to redirect_to(product_path(product))
    end

    it "re-renders the product page when invalid" do
      post product_customer_reviews_path(product), params: {
        customer_review: {
          customer_name: "",
          body: "",
          rating: 5
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("prevented your review from being submitted")
    end
  end
end
