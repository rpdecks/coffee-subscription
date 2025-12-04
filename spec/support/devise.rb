# frozen_string_literal: true

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request

  # Clean up Warden after each test
  config.after(:each, type: :request) do
    Warden.test_reset!
  end
end
