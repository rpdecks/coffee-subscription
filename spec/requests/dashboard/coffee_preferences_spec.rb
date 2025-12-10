require 'rails_helper'

RSpec.describe "Dashboard::CoffeePreferences", type: :request do
  let(:user) { FactoryBot.create(:user) }

  before { sign_in user, scope: :user }

  describe "GET /dashboard/coffee_preference/edit" do
    it "returns http success" do
      get edit_dashboard_coffee_preference_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /dashboard/coffee_preference" do
    it "updates preferences" do
      patch dashboard_coffee_preference_path, params: { coffee_preference: { roast_level: :medium_roast, grind_type: :whole_bean } }
      expect(response).to have_http_status(:redirect)
    end
  end
end
