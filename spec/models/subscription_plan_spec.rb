require 'rails_helper'

RSpec.describe SubscriptionPlan, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:frequency) }
    it { is_expected.to validate_presence_of(:bags_per_delivery) }
    it { is_expected.to validate_presence_of(:price_cents) }
    it { is_expected.to validate_numericality_of(:price_cents).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:bags_per_delivery).is_greater_than(0) }
  end

  describe "associations" do
    it { is_expected.to have_many(:subscriptions) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:frequency).with_values(
      weekly: 0, biweekly: 1, monthly: 2
    ) }
  end

  describe "scopes" do
    let!(:active_plan) { create(:subscription_plan, active: true) }
    let!(:inactive_plan) { create(:subscription_plan, active: false) }

    describe ".active" do
      it "returns only active plans" do
        expect(SubscriptionPlan.active).to include(active_plan)
        expect(SubscriptionPlan.active).not_to include(inactive_plan)
        expect(SubscriptionPlan.active.pluck(:active).uniq).to eq([ true ])
      end
    end
  end

  describe "#price" do
    it "converts price_cents to dollars" do
      plan = build(:subscription_plan, price_cents: 2999)
      expect(plan.price).to eq(29.99)
    end

    it "returns 0.0 when price_cents is nil" do
      plan = build(:subscription_plan, price_cents: nil)
      expect(plan.price).to eq(0.0)
    end
  end

  describe "#price=" do
    it "converts dollars to price_cents" do
      plan = build(:subscription_plan)
      plan.price = 19.99
      expect(plan.price_cents).to eq(1999)
    end

    it "rounds to nearest cent" do
      plan = build(:subscription_plan)
      plan.price = 19.995
      expect(plan.price_cents).to eq(2000)
    end
  end

  describe "#frequency_in_days" do
    it "returns 7 for weekly" do
      plan = build(:subscription_plan, frequency: :weekly)
      expect(plan.frequency_in_days).to eq(7)
    end

    it "returns 14 for biweekly" do
      plan = build(:subscription_plan, frequency: :biweekly)
      expect(plan.frequency_in_days).to eq(14)
    end

    it "returns 30 for monthly" do
      plan = build(:subscription_plan, frequency: :monthly)
      expect(plan.frequency_in_days).to eq(30)
    end
  end

  describe "#name_with_frequency" do
    it "combines name and titleized frequency" do
      plan = build(:subscription_plan, name: "Coffee Lover", frequency: :biweekly)
      expect(plan.name_with_frequency).to eq("Coffee Lover (Biweekly)")
    end
  end
end
