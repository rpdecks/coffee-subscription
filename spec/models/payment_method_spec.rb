require 'rails_helper'

RSpec.describe PaymentMethod, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:stripe_payment_method_id) }
    it { is_expected.to validate_presence_of(:card_brand) }
    it { is_expected.to validate_presence_of(:last_four) }
    it { is_expected.to validate_presence_of(:exp_month) }
    it { is_expected.to validate_presence_of(:exp_year) }
    it { is_expected.to validate_numericality_of(:exp_month).only_integer }
    it { is_expected.to validate_numericality_of(:exp_year).only_integer }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let!(:default_pm) { create(:payment_method, user: user, is_default: true) }
    let!(:non_default_pm) { create(:payment_method, user: user, is_default: false) }

    describe ".default" do
      it "returns only default payment methods" do
        expect(PaymentMethod.default).to eq([ default_pm ])
      end
    end
  end

  describe "#display_name" do
    it "formats card brand and last four digits" do
      pm = build(:payment_method, card_brand: "Visa", last_four: "4242")
      expect(pm.display_name).to eq("Visa ending in 4242")
    end
  end

  describe "#expired?" do
    it "returns true for expired card" do
      pm = build(:payment_method, exp_month: 1, exp_year: 2020)
      expect(pm.expired?).to be true
    end

    it "returns false for current month card" do
      pm = build(:payment_method, exp_month: Date.today.month, exp_year: Date.today.year)
      expect(pm.expired?).to be false
    end

    it "returns false for future card" do
      pm = build(:payment_method, exp_month: 12, exp_year: Date.today.year + 2)
      expect(pm.expired?).to be false
    end
  end

  describe "callbacks" do
    let(:user) { create(:user) }

    describe "ensure_only_one_default" do
      it "unsets other default payment methods" do
        old_default = create(:payment_method, user: user, is_default: true)
        new_default = create(:payment_method, user: user, is_default: true)

        expect(old_default.reload.is_default).to be false
        expect(new_default.reload.is_default).to be true
      end

      it "does not run if payment method is not default" do
        first_pm = create(:payment_method, user: user, is_default: true)
        second_pm = create(:payment_method, user: user, is_default: false)

        expect(first_pm.reload.is_default).to be true
        expect(second_pm.reload.is_default).to be false
      end
    end
  end
end
