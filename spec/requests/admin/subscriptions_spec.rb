# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Subscriptions", type: :request do
  let(:admin) { create(:admin_user) }
  let(:customer) { create(:customer_user) }
  let(:subscription_plan) { create(:subscription_plan) }
  let!(:subscriptions) { create_list(:subscription, 3, user: customer, subscription_plan: subscription_plan) }

  before do
    sign_in admin, scope: :user
  end

  describe "GET /admin/subscriptions" do
    it "returns http success" do
      get admin_subscriptions_path
      expect(response).to have_http_status(:success)
    end

    it "displays all subscriptions" do
      get admin_subscriptions_path
      subscriptions.each do |subscription|
        expect(response.body).to include(subscription.user.email)
      end
    end

    context "with pagination" do
      before { create_list(:subscription, 30, user: customer, subscription_plan: subscription_plan) }

      it "paginates results" do
        get admin_subscriptions_path
        expect(response.body).to match(/pagination/i)
      end
    end

    context "with status filter" do
      let!(:active_customer) { create(:customer_user) }
      let!(:paused_customer) { create(:customer_user) }
      let!(:cancelled_customer) { create(:customer_user) }
      let!(:active_subscription) { create(:subscription, :active, user: active_customer, subscription_plan: subscription_plan) }
      let!(:paused_subscription) { create(:subscription, :paused, user: paused_customer, subscription_plan: subscription_plan) }
      let!(:cancelled_subscription) { create(:subscription, :cancelled, user: cancelled_customer, subscription_plan: subscription_plan) }

      it "filters by active status" do
        get admin_subscriptions_path, params: { status: "active" }
        expect(response.body).to include(active_subscription.user.email)
        expect(response.body).not_to include(cancelled_subscription.user.email)
      end

      it "filters by paused status" do
        get admin_subscriptions_path, params: { status: "paused" }
        expect(response.body).to include(paused_subscription.user.email)
      end
    end

    context "with search" do
      let!(:searchable_customer) { create(:customer_user, email: "searchsub@example.com") }
      let!(:searchable_subscription) { create(:subscription, user: searchable_customer, subscription_plan: subscription_plan) }

      it "finds subscriptions by customer email" do
        get admin_subscriptions_path, params: { search: "searchsub" }
        expect(response.body).to include("searchsub@example.com")
      end
    end
  end

  describe "GET /admin/subscriptions/:id" do
    let(:subscription) { subscriptions.first }
    let!(:order) { create(:order, user: subscription.user, subscription: subscription, shipping_address: create(:address, user: subscription.user)) }

    it "returns http success" do
      get admin_subscription_path(subscription)
      expect(response).to have_http_status(:success)
    end

    it "displays subscription details" do
      get admin_subscription_path(subscription)
      expect(response.body).to include(subscription.subscription_plan.name)
      expect(response.body).to include(subscription.user.email)
    end

    it "displays associated orders" do
      get admin_subscription_path(subscription)
      expect(response.body).to include(order.order_number)
    end
  end
end
