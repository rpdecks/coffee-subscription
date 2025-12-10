# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Dashboard", type: :request do
  let(:admin) { create(:admin_user) }
  let(:customer) { create(:customer_user) }
  let!(:subscription_plan) { create(:subscription_plan) }
  let!(:address) { create(:address, user: customer) }

  before do
    sign_in admin, scope: :user
  end

  describe "GET /admin" do
    let!(:subscriptions) { create_list(:subscription, 3, :active, user: customer, subscription_plan: subscription_plan) }
    let!(:orders) { create_list(:order, 5, user: customer, subscription: subscriptions.first, shipping_address: address) }

    it "returns http success" do
      get admin_root_path
      expect(response).to have_http_status(:success)
    end

    it "displays active subscriptions count" do
      get admin_root_path
      expect(response.body).to include("3") # 3 active subscriptions
    end

    it "displays total customers count" do
      get admin_root_path
      expect(response.body).to include("Total Customers")
      # Check for customer count - should match the number of customer users in fixtures
      expect(response.body).to match(/Total Customers.*?(\d+)/m)
    end

    it "displays recent orders" do
      recent_order = orders.last
      get admin_root_path
      expect(response.body).to include(recent_order.order_number)
    end

    context "when not logged in" do
      before { sign_out admin }

      it "redirects to sign in" do
        get admin_root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as customer" do
      before do
        sign_out admin
        sign_in customer, scope: :user
      end

      it "redirects to root" do
        get admin_root_path
        expect(response).to redirect_to(root_path)
      end

      it "sets flash alert" do
        get admin_root_path
        follow_redirect!
        expect(flash[:alert]).to be_present
      end
    end
  end
end
