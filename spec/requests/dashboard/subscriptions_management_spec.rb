# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Dashboard::Subscriptions", type: :request do
  let(:user) { create(:customer_user) }
  let(:plan) { create(:subscription_plan) }
  let!(:address) { create(:address, user: user) }
  let!(:payment_method) { create(:payment_method, user: user) }

  before do
    sign_in user, scope: :user
  end

  describe "GET /dashboard/subscriptions/:id" do
    let!(:subscription) { create(:subscription, :active, user: user, subscription_plan: plan) }

    it "returns http success" do
      get dashboard_subscription_path(subscription)
      expect(response).to have_http_status(:success)
    end

    it "displays subscription details" do
      get dashboard_subscription_path(subscription)
      expect(response.body).to include(plan.name)
      expect(response.body).to include(subscription.status.titleize)
    end
  end

  describe "GET /dashboard/subscriptions/:id/edit" do
    let!(:subscription) { create(:subscription, :active, user: user) }

    it "returns http success" do
      get edit_dashboard_subscription_path(subscription)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /dashboard/subscriptions/:id" do
    let!(:subscription) { create(:subscription, :active, user: user) }
    let(:new_plan) { create(:subscription_plan) }

    context "with valid attributes" do
      it "updates the subscription" do
        patch dashboard_subscription_path(subscription), params: {
          subscription: { subscription_plan_id: new_plan.id }
        }

        expect(subscription.reload.subscription_plan).to eq(new_plan)
        expect(response).to redirect_to(dashboard_subscription_path(subscription))
        expect(flash[:notice]).to include('updated')
      end
    end

    context "with invalid attributes" do
      it "renders edit form" do
        patch dashboard_subscription_path(subscription), params: {
          subscription: { subscription_plan_id: nil }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /dashboard/subscriptions/:id/pause" do
    let!(:subscription) { create(:subscription, :active, user: user, stripe_subscription_id: 'sub_test123') }

    context "when subscription is active" do
      it "pauses the subscription" do
        allow(StripeService).to receive(:pause_subscription)

        post pause_dashboard_subscription_path(subscription)

        expect(subscription.reload.status).to eq('paused')
        expect(response).to redirect_to(dashboard_subscription_path(subscription))
        expect(flash[:notice]).to include('paused')
      end

      it "pauses in Stripe" do
        expect(StripeService).to receive(:pause_subscription).with('sub_test123')

        post pause_dashboard_subscription_path(subscription)
      end
    end

    context "when subscription cannot be paused" do
      let!(:subscription) { create(:subscription, status: :cancelled, user: user) }

      it "redirects with error" do
        post pause_dashboard_subscription_path(subscription)

        expect(subscription.reload.status).to eq('cancelled')
        expect(flash[:alert]).to include('cannot be paused')
      end
    end

    context "when Stripe service fails" do
      it "redirects with error message" do
        allow(StripeService).to receive(:pause_subscription).and_raise(
          StripeService::StripeError.new('Subscription already paused')
        )

        post pause_dashboard_subscription_path(subscription)

        expect(flash[:alert]).to include('Subscription already paused')
      end
    end
  end

  describe "POST /dashboard/subscriptions/:id/resume" do
    let!(:subscription) { create(:subscription, status: :paused, user: user, stripe_subscription_id: 'sub_test123') }

    context "when subscription is paused" do
      it "resumes the subscription" do
        allow(StripeService).to receive(:resume_subscription)

        post resume_dashboard_subscription_path(subscription)

        expect(subscription.reload.status).to eq('active')
        expect(subscription.next_delivery_date).to be_present
        expect(response).to redirect_to(dashboard_subscription_path(subscription))
        expect(flash[:notice]).to include('resumed')
      end

      it "resumes in Stripe" do
        expect(StripeService).to receive(:resume_subscription).with('sub_test123')

        post resume_dashboard_subscription_path(subscription)
      end
    end

    context "when subscription cannot be resumed" do
      let!(:subscription) { create(:subscription, :active, user: user) }

      it "redirects with error" do
        post resume_dashboard_subscription_path(subscription)

        expect(flash[:alert]).to include('cannot be resumed')
      end
    end
  end

  describe "POST /dashboard/subscriptions/:id/cancel" do
    let!(:subscription) { create(:subscription, :active, user: user, stripe_subscription_id: 'sub_test123') }

    context "when subscription is active" do
      it "cancels the subscription" do
        allow(StripeService).to receive(:cancel_subscription)

        post cancel_dashboard_subscription_path(subscription)

        expect(subscription.reload.status).to eq('cancelled')
        expect(subscription.cancelled_at).to be_present
        expect(response).to redirect_to(dashboard_root_path)
        expect(flash[:notice]).to include('cancelled')
      end

      it "cancels in Stripe at period end" do
        expect(StripeService).to receive(:cancel_subscription).with('sub_test123', cancel_at_period_end: true)

        post cancel_dashboard_subscription_path(subscription)
      end
    end

    context "when subscription cannot be cancelled" do
      let!(:subscription) { create(:subscription, status: :cancelled, user: user) }

      it "redirects with error" do
        post cancel_dashboard_subscription_path(subscription)

        expect(flash[:alert]).to include('cannot be cancelled')
      end
    end
  end

  describe "POST /dashboard/subscriptions/:id/skip_delivery" do
    let!(:subscription) { create(:subscription, :active, user: user, next_delivery_date: Date.today + 7.days) }

    context "when subscription is active" do
      it "skips the next delivery" do
        original_date = subscription.next_delivery_date

        post skip_delivery_dashboard_subscription_path(subscription)

        expect(subscription.reload.next_delivery_date).to be > original_date
        expect(flash[:notice]).to include('skipped')
      end
    end

    context "when subscription is not active" do
      let!(:subscription) { create(:subscription, status: :paused, user: user) }

      it "redirects with error" do
        post skip_delivery_dashboard_subscription_path(subscription)

        expect(flash[:alert]).to include('Cannot skip delivery')
      end
    end
  end
end
