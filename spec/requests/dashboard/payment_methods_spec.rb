require 'rails_helper'

RSpec.describe "Dashboard::PaymentMethods", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/dashboard/payment_methods/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/dashboard/payment_methods/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/dashboard/payment_methods/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/dashboard/payment_methods/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
