require 'rails_helper'

RSpec.describe "Dashboard::CoffeePreferences", type: :request do
  describe "GET /edit" do
    it "returns http success" do
      get "/dashboard/coffee_preferences/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/dashboard/coffee_preferences/update"
      expect(response).to have_http_status(:success)
    end
  end
end
