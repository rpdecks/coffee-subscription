# frozen_string_literal: true

# Service object for Stripe API interactions
class StripeService
  class StripeError < StandardError; end

  # Create a Stripe customer for a user
  def self.create_customer(user)
    return user.stripe_customer_id if user.stripe_customer_id.present?

    customer = Stripe::Customer.create({
      email: user.email,
      name: user.full_name,
      phone: user.phone,
      metadata: {
        user_id: user.id
      }
    })

    user.update!(stripe_customer_id: customer.id)
    customer.id
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe customer creation failed: #{e.message}")
    raise StripeError, "Failed to create Stripe customer: #{e.message}"
  end

  # Create a checkout session for subscription
  def self.create_checkout_session(user:, plan:, success_url:, cancel_url:, metadata: {})
    # Ensure user has a Stripe customer ID
    stripe_customer_id = create_customer(user)

    # Create checkout session
    session = Stripe::Checkout::Session.create({
      customer: stripe_customer_id,
      mode: 'subscription',
      payment_method_types: ['card'],
      line_items: [{
        price_data: {
          currency: 'usd',
          product_data: {
            name: plan.name,
            description: plan.description
          },
          recurring: {
            interval: 'month',
            interval_count: 1
          },
          unit_amount: plan.price_cents
        },
        quantity: 1
      }],
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: metadata.merge({
        user_id: user.id,
        subscription_plan_id: plan.id
      })
    })

    session
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe checkout session creation failed: #{e.message}")
    raise StripeError, "Failed to create checkout session: #{e.message}"
  end

  # Add a payment method to a customer
  def self.attach_payment_method(user:, payment_method_id:, set_as_default: false)
    stripe_customer_id = create_customer(user)

    # Attach the payment method to the customer
    payment_method = Stripe::PaymentMethod.attach(
      payment_method_id,
      { customer: stripe_customer_id }
    )

    # Set as default if requested
    if set_as_default
      Stripe::Customer.update(
        stripe_customer_id,
        invoice_settings: {
          default_payment_method: payment_method_id
        }
      )
    end

    # Store payment method details in our database
    save_payment_method(user, payment_method, set_as_default)
  rescue Stripe::StripeError => e
    Rails.logger.error("Failed to attach payment method: #{e.message}")
    raise StripeError, "Failed to attach payment method: #{e.message}"
  end

  # Remove a payment method
  def self.detach_payment_method(payment_method_id)
    Stripe::PaymentMethod.detach(payment_method_id)
  rescue Stripe::StripeError => e
    Rails.logger.error("Failed to detach payment method: #{e.message}")
    raise StripeError, "Failed to detach payment method: #{e.message}"
  end

  # Create a subscription in Stripe
  def self.create_subscription(user:, plan:, payment_method_id:, metadata: {})
    stripe_customer_id = create_customer(user)

    subscription = Stripe::Subscription.create({
      customer: stripe_customer_id,
      items: [{
        price_data: {
          currency: 'usd',
          product_data: {
            name: plan.name,
            description: plan.description
          },
          recurring: {
            interval: 'month',
            interval_count: 1
          },
          unit_amount: plan.price_cents
        }
      }],
      default_payment_method: payment_method_id,
      metadata: metadata.merge({
        user_id: user.id,
        subscription_plan_id: plan.id
      })
    })

    subscription
  rescue Stripe::StripeError => e
    Rails.logger.error("Failed to create subscription: #{e.message}")
    raise StripeError, "Failed to create subscription: #{e.message}"
  end

  # Cancel a subscription
  def self.cancel_subscription(stripe_subscription_id, cancel_at_period_end: true)
    if cancel_at_period_end
      Stripe::Subscription.update(
        stripe_subscription_id,
        cancel_at_period_end: true
      )
    else
      Stripe::Subscription.cancel(stripe_subscription_id)
    end
  rescue Stripe::StripeError => e
    Rails.logger.error("Failed to cancel subscription: #{e.message}")
    raise StripeError, "Failed to cancel subscription: #{e.message}"
  end

  # Pause a subscription
  def self.pause_subscription(stripe_subscription_id)
    Stripe::Subscription.update(
      stripe_subscription_id,
      pause_collection: {
        behavior: 'void'
      }
    )
  rescue Stripe::StripeError => e
    Rails.logger.error("Failed to pause subscription: #{e.message}")
    raise StripeError, "Failed to pause subscription: #{e.message}"
  end

  # Resume a subscription
  def self.resume_subscription(stripe_subscription_id)
    Stripe::Subscription.update(
      stripe_subscription_id,
      pause_collection: ''
    )
  rescue Stripe::StripeError => e
    Rails.logger.error("Failed to resume subscription: #{e.message}")
    raise StripeError, "Failed to resume subscription: #{e.message}"
  end

  # Retrieve a payment method
  def self.retrieve_payment_method(payment_method_id)
    Stripe::PaymentMethod.retrieve(payment_method_id)
  rescue Stripe::StripeError => e
    Rails.logger.error("Failed to retrieve payment method: #{e.message}")
    raise StripeError, "Failed to retrieve payment method: #{e.message}"
  end

  private

  # Save payment method details to our database
  def self.save_payment_method(user, stripe_payment_method, is_default)
    # Check if payment method already exists
    existing = user.payment_methods.find_by(stripe_payment_method_id: stripe_payment_method.id)
    return existing if existing

    user.payment_methods.create!(
      stripe_payment_method_id: stripe_payment_method.id,
      card_brand: stripe_payment_method.card.brand,
      last_four: stripe_payment_method.card.last4,
      exp_month: stripe_payment_method.card.exp_month,
      exp_year: stripe_payment_method.card.exp_year,
      is_default: is_default
    )
  end
end
