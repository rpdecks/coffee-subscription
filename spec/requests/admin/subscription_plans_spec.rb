# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::SubscriptionPlans", type: :request do
  let(:admin) { create(:admin_user) }
  let!(:plans) { create_list(:subscription_plan, 3) }

  before do
    sign_in admin, scope: :user
  end

  describe "GET /admin/subscription_plans" do
    it "returns http success" do
      get admin_subscription_plans_path
      expect(response).to have_http_status(:success)
    end

    it "displays all plans" do
      get admin_subscription_plans_path
      plans.each do |plan|
        expect(response.body).to include(plan.name)
      end
    end

    context "with active filter" do
      let!(:active_plan) { create(:subscription_plan, active: true) }
      let!(:inactive_plan) { create(:subscription_plan, :inactive) }

      it "filters by active plans" do
        get admin_subscription_plans_path, params: { active: "true" }
        expect(response.body).to include(active_plan.name)
      end

      it "filters by inactive plans" do
        get admin_subscription_plans_path, params: { active: "false" }
        expect(response.body).to include(inactive_plan.name)
      end
    end
  end

  describe "GET /admin/subscription_plans/:id" do
    let(:plan) { plans.first }
    let(:customer) { create(:customer_user) }
    let!(:subscription) { create(:subscription, subscription_plan: plan, user: customer) }

    it "returns http success" do
      get admin_subscription_plan_path(plan)
      expect(response).to have_http_status(:success)
    end

    it "displays plan details" do
      get admin_subscription_plan_path(plan)
      expect(response.body).to include(plan.name)
      expect(response.body).to include(plan.description)
    end

    it "displays active subscriptions count" do
      get admin_subscription_plan_path(plan)
      expect(response.body).to include("1") # One active subscription
    end
  end

  describe "GET /admin/subscription_plans/new" do
    it "returns http success" do
      get new_admin_subscription_plan_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/subscription_plans" do
    let(:valid_attributes) do
      {
        name: "New Plan",
        description: "A new subscription plan",
        frequency: "monthly",
        bags_per_delivery: 2,
        price_cents: 3200,
        active: true
      }
    end

    it "creates a new plan" do
      expect {
        post admin_subscription_plans_path, params: { subscription_plan: valid_attributes }
      }.to change(SubscriptionPlan, :count).by(1)
    end

    it "redirects to plan show page" do
      post admin_subscription_plans_path, params: { subscription_plan: valid_attributes }
      expect(response).to redirect_to(admin_subscription_plan_path(SubscriptionPlan.last))
    end
  end

  describe "GET /admin/subscription_plans/:id/edit" do
    let(:plan) { plans.first }

    it "returns http success" do
      get edit_admin_subscription_plan_path(plan)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/subscription_plans/:id" do
    let(:plan) { plans.first }

    it "updates the plan" do
      patch admin_subscription_plan_path(plan), params: { subscription_plan: { name: "Updated Plan" } }
      expect(plan.reload.name).to eq("Updated Plan")
    end

    it "redirects to plan show page" do
      patch admin_subscription_plan_path(plan), params: { subscription_plan: { name: "Updated Plan" } }
      expect(response).to redirect_to(admin_subscription_plan_path(plan))
    end
  end

  describe "DELETE /admin/subscription_plans/:id" do
    let(:plan) { create(:subscription_plan) }

    it "destroys the plan" do
      expect {
        delete admin_subscription_plan_path(plan)
      }.to change(SubscriptionPlan, :count).by(-1)
    end

    it "redirects to plans index" do
      delete admin_subscription_plan_path(plan)
      expect(response).to redirect_to(admin_subscription_plans_path)
    end
  end
end
