require 'rails_helper'

RSpec.describe CreateStripeCustomerJob, type: :job do
  describe "#perform" do
    let(:user) { create(:user, stripe_customer_id: nil) }

    context "when user exists and has no stripe_customer_id" do
      it "creates a Stripe customer" do
        expect(StripeService).to receive(:create_customer).with(user).and_return("cus_123")
        described_class.perform_now(user.id)
      end
    end

    context "when user already has a stripe_customer_id" do
      let(:user) { create(:user, stripe_customer_id: "cus_existing") }

      it "does not create a new customer" do
        expect(StripeService).not_to receive(:create_customer)
        described_class.perform_now(user.id)
      end
    end

    context "when user does not exist" do
      it "handles the error gracefully" do
        expect {
          described_class.perform_now(999999)
        }.not_to raise_error
      end
    end
  end
end
