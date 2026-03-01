# frozen_string_literal: true

# Global Stripe API stubs for the test suite.
#
# StripeService.create_customer(user) is called internally by several service
# methods (attach_payment_method, create_checkout_session, etc.) before the
# more specific Stripe calls that individual specs stub out. It calls
# Stripe::Customer.retrieve to verify an existing customer ID, then
# Stripe::Customer.create if one doesn't exist yet.
#
# Without these stubs, any test running in an environment with an invalid or
# missing Stripe API key (e.g. CI) fails with:
#   "Failed to create Stripe customer: Your API key is invalid, ..."
# …before the per-example stubs ever fire.
#
# Individual specs can override these with their own allow/expect stubs.
RSpec.configure do |config|
  config.before(:each) do
    allow(Stripe::Customer).to receive(:retrieve) do |id, *|
      double("Stripe::Customer", id: id)
    end

    allow(Stripe::Customer).to receive(:create) do |params, *|
      double("Stripe::Customer", id: "cus_test_created")
    end
  end
end
