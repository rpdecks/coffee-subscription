require 'rails_helper'

RSpec.describe Subscription, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:status) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:subscription_plan) }
    it { is_expected.to belong_to(:shipping_address).class_name('Address').optional }
    it { is_expected.to belong_to(:payment_method).optional }
    it { is_expected.to have_many(:orders) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(
      active: 0, paused: 1, cancelled: 2, past_due: 3
    ) }
  end

  describe "scopes" do
    let!(:active_sub) { create(:subscription, status: :active) }
    let!(:paused_sub) { create(:subscription, status: :paused) }
    let!(:cancelled_sub) { create(:subscription, status: :cancelled) }

    describe ".active_subscriptions" do
      it "returns only active subscriptions" do
        expect(Subscription.active_subscriptions).to include(active_sub)
        expect(Subscription.active_subscriptions).not_to include(paused_sub, cancelled_sub)
        expect(Subscription.active_subscriptions.pluck(:status).uniq).to eq([ "active" ])
      end
    end

    describe ".due_for_delivery" do
      let!(:due_today) { create(:subscription, status: :active, next_delivery_date: Date.today) }
      let!(:due_yesterday) { create(:subscription, status: :active, next_delivery_date: Date.yesterday) }
      let!(:due_tomorrow) { create(:subscription, status: :active, next_delivery_date: Date.tomorrow) }

      it "returns subscriptions due today or earlier" do
        subs = Subscription.due_for_delivery
        expect(subs).to include(due_today, due_yesterday)
        expect(subs).not_to include(due_tomorrow)
      end
    end
  end

  describe "#pause!" do
    let(:subscription) { create(:subscription, status: :active) }

    it "updates status to paused" do
      subscription.pause!
      expect(subscription.reload.status).to eq("paused")
    end
  end

  describe "#resume!" do
    context "when subscription is paused" do
      let(:subscription) { create(:subscription, status: :paused) }

      it "updates status to active" do
        subscription.resume!
        expect(subscription.reload.status).to eq("active")
      end
    end

    context "when subscription is not paused" do
      let(:subscription) { create(:subscription, status: :cancelled) }

      it "does not change status" do
        subscription.resume!
        expect(subscription.reload.status).to eq("cancelled")
      end
    end
  end

  describe "#cancel!" do
    let(:subscription) { create(:subscription, status: :active) }

    it "updates status to cancelled" do
      subscription.cancel!
      expect(subscription.reload.status).to eq("cancelled")
    end
  end

  describe "#calculate_next_delivery_date" do
    let(:plan) { create(:subscription_plan, frequency: :biweekly) }  # 14 days
    let(:subscription) { create(:subscription, subscription_plan: plan, status: :active) }

    context "when next_delivery_date exists" do
      before { subscription.update(next_delivery_date: Date.new(2025, 1, 1)) }

      it "adds frequency days to next_delivery_date" do
        result = subscription.calculate_next_delivery_date
        expect(result).to eq(Date.new(2025, 1, 15))
      end
    end

    context "when next_delivery_date is nil" do
      before { subscription.update(next_delivery_date: nil) }

      it "uses today as base date" do
        result = subscription.calculate_next_delivery_date
        expect(result).to eq(Date.today + 14.days)
      end
    end

    context "when subscription is not active" do
      before { subscription.update(status: :paused) }

      it "returns nil" do
        expect(subscription.calculate_next_delivery_date).to be_nil
      end
    end
  end
end
