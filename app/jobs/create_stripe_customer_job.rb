# frozen_string_literal: true

class CreateStripeCustomerJob < ApplicationJob
  queue_as :default

  retry_on StripeService::StripeError, wait: :exponentially_longer, attempts: 3

  def perform(user_id)
    user = User.find(user_id)
    return if user.stripe_customer_id.present?

    StripeService.create_customer(user)
    Rails.logger.info("Created Stripe customer for user #{user.id}")
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error("User #{user_id} not found for Stripe customer creation")
  end
end
