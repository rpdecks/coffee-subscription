require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  let(:user) { FactoryBot.create(:user) }

  before { sign_in user }

  describe "GET /dashboard" do
    it "returns http success" do
      get dashboard_root_path
      expect(response).to have_http_status(:success)
    end
  end
end
