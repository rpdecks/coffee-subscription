require 'rails_helper'

RSpec.describe "Subscription Checkout with Shipping Address", type: :request do
  let(:user) { create(:customer_user) }
  let(:plan) { create(:subscription_plan, price_cents: 1800) }
  let(:coffee) { create(:product, :coffee) }

  before do
    sign_in user, scope: :user
  end

  describe "POST /subscribe/checkout" do
    context "with new shipping address" do
      let(:address_params) do
        {
          address: {
            street_address: "456 Coffee Lane",
            street_address_2: "Apt 2B",
            city: "Seattle",
            state: "WA",
            zip_code: "98101",
            country: "USA"
          }
        }
      end

      let(:checkout_params) do
        {
          plan_id: plan.id,
          bag_size: "12oz",
          frequency: "weekly",
          grind_type: "whole_bean",
          coffee_id: coffee.id,
          address_id: "new"
        }.merge(address_params)
      end

      it "creates a new shipping address for the user" do
        # Stub Stripe checkout session creation
        allow(StripeService).to receive(:create_checkout_session).and_return(
          double(url: "https://checkout.stripe.com/test")
        )

        expect {
          post subscription_checkout_path, params: checkout_params
        }.to change(user.addresses, :count).by(1)

        new_address = user.addresses.last
        expect(new_address.street_address).to eq("456 Coffee Lane")
        expect(new_address.street_address_2).to eq("Apt 2B")
        expect(new_address.city).to eq("Seattle")
        expect(new_address.state).to eq("WA")
        expect(new_address.zip_code).to eq("98101")
        expect(new_address.address_type).to eq("shipping")
      end

      it "stores shipping_address_id in session" do
        allow(StripeService).to receive(:create_checkout_session).and_return(
          double(url: "https://checkout.stripe.com/test")
        )

        post subscription_checkout_path, params: checkout_params

        expect(session[:pending_subscription][:shipping_address_id]).to be_present
      end

      it "passes shipping_address_id to Stripe metadata" do
        expect(StripeService).to receive(:create_checkout_session) do |args|
          expect(args[:metadata][:shipping_address_id]).to be_present
          double(url: "https://checkout.stripe.com/test")
        end

        post subscription_checkout_path, params: checkout_params
      end

      it "redirects to Stripe checkout" do
        allow(StripeService).to receive(:create_checkout_session).and_return(
          double(url: "https://checkout.stripe.com/test")
        )

        post subscription_checkout_path, params: checkout_params

        expect(response).to redirect_to("https://checkout.stripe.com/test")
      end
    end

    context "with existing shipping address" do
      let!(:existing_address) { create(:address, user: user, address_type: :shipping) }

      let(:checkout_params) do
        {
          plan_id: plan.id,
          bag_size: "12oz",
          frequency: "weekly",
          grind_type: "whole_bean",
          coffee_id: coffee.id,
          address_id: existing_address.id
        }
      end

      it "does not create a new address" do
        allow(StripeService).to receive(:create_checkout_session).and_return(
          double(url: "https://checkout.stripe.com/test")
        )

        expect {
          post subscription_checkout_path, params: checkout_params
        }.not_to change(user.addresses, :count)
      end

      it "uses the existing address" do
        expect(StripeService).to receive(:create_checkout_session) do |args|
          expect(args[:metadata][:shipping_address_id]).to eq(existing_address.id.to_s)
          double(url: "https://checkout.stripe.com/test")
        end

        post subscription_checkout_path, params: checkout_params
      end
    end

    context "without shipping address" do
      let(:checkout_params) do
        {
          plan_id: plan.id,
          bag_size: "12oz",
          frequency: "weekly",
          grind_type: "whole_bean",
          coffee_id: coffee.id
        }
      end

      it "redirects back with error" do
        post subscription_checkout_path, params: checkout_params

        expect(response).to redirect_to(customize_subscription_path(plan_id: plan.id))
        expect(flash[:alert]).to eq("Please provide a valid shipping address")
      end

      it "does not call Stripe" do
        expect(StripeService).not_to receive(:create_checkout_session)

        post subscription_checkout_path, params: checkout_params
      end
    end

    context "with invalid address data" do
      let(:checkout_params) do
        {
          plan_id: plan.id,
          bag_size: "12oz",
          frequency: "weekly",
          grind_type: "whole_bean",
          coffee_id: coffee.id,
          address_id: "new",
          address: {
            street_address: "",
            city: "Seattle"
          }
        }
      end

      it "redirects back with error" do
        post subscription_checkout_path, params: checkout_params

        expect(response).to redirect_to(customize_subscription_path(plan_id: plan.id))
        expect(flash[:alert]).to eq("Please provide a valid shipping address")
      end
    end
  end
end
