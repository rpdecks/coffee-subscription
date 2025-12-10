require 'rails_helper'

RSpec.describe "Subscriptions", type: :request do
  describe "GET /subscribe" do
    it "returns http success" do
      get subscribe_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /subscribe/plans" do
    it "returns http success" do
      get subscription_plans_path
      expect(response).to have_http_status(:success)
    end
  end
end
