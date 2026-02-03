require "rails_helper"

RSpec.describe "Gear", type: :request do
  describe "GET /gear" do
    it "returns http success" do
      get gear_path
      expect(response).to have_http_status(:success)
    end
  end
end
