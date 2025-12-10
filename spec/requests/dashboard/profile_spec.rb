require 'rails_helper'

RSpec.describe "Dashboard::Profiles", type: :request do
  let(:user) { FactoryBot.create(:user) }

  before { sign_in user }

  describe "GET /dashboard/profile/edit" do
    it "returns http success" do
      get edit_dashboard_profile_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /dashboard/profile" do
    it "updates profile" do
      patch dashboard_profile_path, params: { user: { first_name: "New Name" } }
      expect(response).to have_http_status(:redirect)
    end
  end
end
