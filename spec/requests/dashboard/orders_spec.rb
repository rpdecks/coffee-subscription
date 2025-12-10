require 'rails_helper'

RSpec.describe "Dashboard::Orders", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:order) { FactoryBot.create(:order, user: user) }

  before { sign_in user }

  describe "GET /dashboard/orders" do
    it "returns http success" do
      get dashboard_orders_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /dashboard/orders/:id" do
    it "returns http success" do
      get dashboard_order_path(order)
      expect(response).to have_http_status(:success)
    end
  end
end
