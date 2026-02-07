require "rails_helper"

RSpec.describe "Subscription checkout newsletter opt-in", type: :request do
  let(:user) { create(:user, email: "customer@example.com") }
  let(:plan) { create(:subscription_plan) }
  let(:coffee) { create(:product, :coffee) }

  before do
    sign_in user
  end

  it "passes opt-in flag through to Stripe metadata" do
    session_double = instance_double(Stripe::Checkout::Session, url: "https://example.test/stripe")

    expect(StripeService).to receive(:create_checkout_session) do |args|
      expect(args[:metadata]).to include("newsletter_opt_in" => "1")
      session_double
    end

    post subscription_checkout_path, params: {
      plan_id: plan.id,
      coffee_id: coffee.id,
      bag_size: "12oz",
      frequency: "weekly",
      grind_type: "whole_bean",
      newsletter_opt_in: "1",
      address_id: "new",
      address: {
        street_address: "123 Maple St",
        street_address_2: "",
        city: "Knoxville",
        state: "TN",
        zip_code: "37902",
        country: "US"
      }
    }

    expect(response).to have_http_status(:redirect)
  end
end
