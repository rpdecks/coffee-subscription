# frozen_string_literal: true

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::ControllerHelpers, type: :controller

  # Stub Stripe customer creation for all tests
  config.before(:each) do
    allow_any_instance_of(User).to receive(:create_stripe_customer).and_return(true)
  end

  # Clean up Warden after each test
  config.after(:each, type: :request) do
    Warden.test_reset!
  end
end
