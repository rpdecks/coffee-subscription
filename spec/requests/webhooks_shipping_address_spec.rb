require 'rails_helper'

RSpec.describe "Webhook Shipping Address Handling", type: :request do
  let(:user) { create(:customer_user, stripe_customer_id: 'cus_test123') }
  let(:plan) { create(:subscription_plan, stripe_plan_id: 'price_test123') }
  let(:address) { create(:address, user: user, address_type: :shipping) }
  let(:payment_method) { create(:payment_method, user: user, is_default: true) }

  before do
    # Stub Stripe verification to bypass signature check and return our event
    allow(Stripe::Webhook).to receive(:construct_event) { stripe_event }

    # Stub WebhookEvent to bypass idempotency check
    allow(WebhookEvent).to receive(:find_or_initialize_by).and_return(
      double(WebhookEvent, persisted?: false, processed_at: nil, event_type: nil, 'event_type=': nil, save!: true, update: true)
    )
  end

  describe "POST /webhooks/stripe with checkout.session.completed" do
    let(:stripe_event) do
      Stripe::Event.construct_from(
        type: 'checkout.session.completed',
        data: {
          object: {
            id: 'cs_test_session',
            customer: user.stripe_customer_id,
            subscription: 'sub_test123',
            metadata: {
              subscription_plan_id: plan.id.to_s,
              bag_size: '12oz',
              frequency: 'weekly',
              grind_type: 'whole_bean',
              coffee_id: '1',
              shipping_address_id: address.id.to_s
            }
          }
        }
      )
    end

    it "creates subscription with the specified shipping address" do
      expect {
        post webhooks_stripe_path, params: {}, headers: { 'HTTP_STRIPE_SIGNATURE' => 'test_sig' }
      }.to change(Subscription, :count).by(1)

      subscription = Subscription.last
      expect(subscription.shipping_address_id).to eq(address.id)
      expect(subscription.shipping_address.street_address).to eq(address.street_address)
    end

    it "uses shipping_address_id from metadata" do
      post webhooks_stripe_path, params: {}, headers: { 'HTTP_STRIPE_SIGNATURE' => 'test_sig' }

      subscription = Subscription.last
      expect(subscription.shipping_address_id).to eq(address.id)
    end

    context "without shipping_address_id in metadata" do
      let(:stripe_event) do
        Stripe::Event.construct_from(
          type: 'checkout.session.completed',
          data: {
            object: {
              id: 'cs_test_session',
              customer: user.stripe_customer_id,
              subscription: 'sub_test123',
              metadata: {
                subscription_plan_id: plan.id.to_s,
                bag_size: '12oz',
                frequency: 'weekly',
                grind_type: 'whole_bean',
                coffee_id: '1'
              }
            }
          }
        )
      end

      it "falls back to user's first shipping address" do
        post webhooks_stripe_path, params: {}, headers: { 'HTTP_STRIPE_SIGNATURE' => 'test_sig' }

        subscription = Subscription.last
        expect(subscription.shipping_address_id).to eq(user.addresses.shipping.first.id)
      end

      context "with no shipping addresses" do
        before do
          address.update(address_type: :billing)
        end

        it "uses any available address" do
          post webhooks_stripe_path, params: {}, headers: { 'HTTP_STRIPE_SIGNATURE' => 'test_sig' }

          subscription = Subscription.last
          expect(subscription.shipping_address_id).to eq(user.addresses.first.id)
        end
      end

      context "with no addresses at all" do
        before do
          user.addresses.destroy_all
        end

        it "creates subscription without address" do
          expect {
            post webhooks_stripe_path, params: {}, headers: { 'HTTP_STRIPE_SIGNATURE' => 'test_sig' }
          }.to change(Subscription, :count).by(1)

          subscription = Subscription.last
          expect(subscription.shipping_address).to be_nil
        end
      end
    end
  end

  describe "Order creation with shipping address" do
    let!(:subscription) do
      create(:subscription,
        user: user,
        subscription_plan: plan,
        shipping_address: address,
        stripe_subscription_id: 'sub_test123'
      )
    end

    let(:stripe_event) do
      Stripe::Event.construct_from(
        type: 'invoice.payment_succeeded',
        data: {
          object: {
            id: 'in_test123',
            subscription: 'sub_test123',
            customer: user.stripe_customer_id
          }
        }
      )
    end

    it "creates order with subscription's shipping address" do
      expect {
        post webhooks_stripe_path, params: {}, headers: { 'HTTP_STRIPE_SIGNATURE' => 'test_sig' }
      }.to change(Order, :count).by(1)

      order = Order.last
      expect(order.shipping_address_id).to eq(address.id)
      expect(order.shipping_address).to eq(address)
    end

    context "when subscription has no shipping address" do
      before do
        subscription.update(shipping_address: nil)
      end

      it "fails to create order" do
        expect {
          post webhooks_stripe_path, params: {}, headers: { 'HTTP_STRIPE_SIGNATURE' => 'test_sig' }
        }.not_to change(Order, :count)
      end

      it "logs error about missing shipping address" do
        expect(Rails.logger).to receive(:error).with(/Shipping address must exist/)

        post webhooks_stripe_path, params: {}, headers: { 'HTTP_STRIPE_SIGNATURE' => 'test_sig' }
      end
    end
  end
end
