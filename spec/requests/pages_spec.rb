require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /about" do
    it "returns http success" do
      get about_path
      expect(response).to have_http_status(:success)
    end

    it "shows only approved testimonials selected for the about page" do
      featured_review = create(:customer_review, :featured_on_about, :general, body: "Acer has become part of our routine.")
      create(:customer_review, :approved, :general, body: "Approved but not featured")
      create(:customer_review, :general, featured_on_about: false, body: "Pending review")

      get about_path

      expect(response.body).to include(featured_review.body.truncate(220))
      expect(response.body).not_to include("Approved but not featured")
      expect(response.body).not_to include("Pending review")
    end
  end

  describe "GET /blog" do
    it "returns http success" do
      get blog_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /faq" do
    it "returns http success" do
      get faq_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /contact" do
    it "returns http success" do
      get contact_path
      expect(response).to have_http_status(:success)
    end
  end
end
