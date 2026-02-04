require "rails_helper"

RSpec.describe "Stripe webhook newsletter opt-in", type: :request do
  it "subscribes the user when checkout metadata includes opt-in" do
    user = create(:user, email: "customer@example.com", stripe_customer_id: "cus_123")

    allow(ButtondownService).to receive(:configured?).and_return(true)
    expect(ButtondownService).to receive(:subscribe).with(email: "customer@example.com").and_return(true)

    payload = {
      id: "evt_1",
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_test_1",
          customer: "cus_123",
          metadata: {
            "order_type" => "one_time",
            "cart_items" => "[]",
            "newsletter_opt_in" => "1"
          }
        }
      }
    }

    post "/webhooks/stripe", params: payload.to_json, headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:ok)
  end
end
