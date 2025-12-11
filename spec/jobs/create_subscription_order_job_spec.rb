require 'rails_helper'

RSpec.describe CreateSubscriptionOrderJob, type: :job do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:address) { create(:address, user: user) }
    let(:plan) { create(:subscription_plan, price_cents: 2999, frequency: :weekly) }
    let(:subscription) { create(:subscription, user: user, subscription_plan: plan, shipping_address: address, next_delivery_date: Date.today) }

    context "when subscription exists" do
      it "creates an order for the subscription" do
        expect {
          described_class.perform_now(subscription.id)
        }.to change(Order, :count).by(1)

        order = Order.last
        expect(order.user).to eq(user)
        expect(order.order_type).to eq("subscription")
        expect(order.status).to eq("pending")
        expect(order.total_cents).to eq(2999)
        expect(order.shipping_address).to eq(address)
      end

      it "updates the next delivery date" do
        frequency_days = plan.frequency_in_days
        original_date = subscription.next_delivery_date

        described_class.perform_now(subscription.id)

        subscription.reload
        expect(subscription.next_delivery_date).to eq(original_date + frequency_days.days)
      end

      it "includes invoice_id if provided" do
        described_class.perform_now(subscription.id, "inv_123")

        order = Order.last
        expect(order.stripe_invoice_id).to eq("inv_123")
      end

      it "enqueues order confirmation email" do
        expect {
          described_class.perform_now(subscription.id)
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end
    end

    context "when order fails to save" do
      before do
        allow_any_instance_of(Order).to receive(:save).and_return(false)
        allow_any_instance_of(Order).to receive(:errors).and_return(double(full_messages: [ "Error message" ]))
      end

      it "does not create an order" do
        expect {
          described_class.perform_now(subscription.id)
        }.not_to change(Order, :count)
      end
    end

    context "when subscription does not exist" do
      it "handles error gracefully" do
        expect {
          described_class.perform_now(999999)
        }.not_to raise_error
      end
    end
  end
end
