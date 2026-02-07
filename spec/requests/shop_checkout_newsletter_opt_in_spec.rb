require "rails_helper"

RSpec.describe "Shop checkout newsletter opt-in", type: :request do
  let(:user) { create(:user, email: "customer@example.com") }
  let(:product) { create(:product) }

  before do
    sign_in user
  end

  it "passes opt-in flag through to Stripe metadata" do
    session_double = instance_double(Stripe::Checkout::Session, url: "https://example.test/stripe")

    expect(StripeService).to receive(:create_product_checkout_session) do |args|
      expect(args[:metadata]).to include("newsletter_opt_in" => "1")
      session_double
    end

    post shop_create_checkout_path,
      params: {
        cart_items: [ { product_id: product.id, quantity: 1 } ],
        newsletter_opt_in: "1"
      },
      as: :json

    expect(response).to have_http_status(:success)
    expect(JSON.parse(response.body)).to include("checkout_url" => "https://example.test/stripe")
  end
end
