# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StripeService do
  let(:user) { create(:customer_user) }
  let(:plan) { create(:subscription_plan, price_cents: 2500) }

  # Mock Stripe responses
  let(:stripe_customer) do
    double(
      'Stripe::Customer',
      id: 'cus_test123',
      email: user.email,
      name: user.full_name
    )
  end

  let(:stripe_payment_method) do
    double(
      'Stripe::PaymentMethod',
      id: 'pm_test123',
      customer: nil,
      card: double(
        brand: 'visa',
        last4: '4242',
        exp_month: 12,
        exp_year: 2025
      )
    )
  end

  let(:stripe_checkout_session) do
    double(
      'Stripe::Checkout::Session',
      id: 'cs_test123',
      url: 'https://checkout.stripe.com/test',
      customer: 'cus_test123',
      subscription: 'sub_test123',
      metadata: {}
    )
  end

  let(:stripe_subscription) do
    double(
      'Stripe::Subscription',
      id: 'sub_test123',
      customer: 'cus_test123',
      status: 'active'
    )
  end

  describe '.create_customer' do
    context 'when user does not have a Stripe customer ID' do
      it 'creates a Stripe customer and updates the user' do
        expect(Stripe::Customer).to receive(:create).with(
          hash_including(
            email: user.email,
            name: user.full_name,
            phone: user.phone
          )
        ).and_return(stripe_customer)

        result = described_class.create_customer(user)

        expect(result).to eq('cus_test123')
        expect(user.reload.stripe_customer_id).to eq('cus_test123')
      end
    end

    context 'when user already has a Stripe customer ID' do
      before { user.update(stripe_customer_id: 'cus_existing') }

      it 'returns the existing customer ID when customer exists in Stripe' do
        expect(Stripe::Customer).to receive(:retrieve).with('cus_existing').and_return(double('Stripe::Customer', id: 'cus_existing'))
        expect(Stripe::Customer).not_to receive(:create)

        result = described_class.create_customer(user)

        expect(result).to eq('cus_existing')
      end

      it 'recreates the customer when the stored Stripe customer is missing' do
        allow(Stripe::Customer).to receive(:retrieve).with('cus_existing').and_raise(
          Stripe::InvalidRequestError.new("No such customer: 'cus_existing'", 'id')
        )
        expect(Stripe::Customer).to receive(:create).and_return(stripe_customer)

        result = described_class.create_customer(user)

        expect(result).to eq('cus_test123')
        expect(user.reload.stripe_customer_id).to eq('cus_test123')
      end
    end

    context 'when Stripe API fails' do
      it 'raises a StripeError' do
        allow(Stripe::Customer).to receive(:create).and_raise(
          Stripe::InvalidRequestError.new('Invalid request', 'email')
        )

        expect {
          described_class.create_customer(user)
        }.to raise_error(StripeService::StripeError, /Failed to create Stripe customer/)
      end
    end
  end

  describe '.create_checkout_session' do
    let(:success_url) { 'http://test.com/success' }
    let(:cancel_url) { 'http://test.com/cancel' }

    before do
      user.update(stripe_customer_id: 'cus_test123')
      allow(Stripe::Customer).to receive(:retrieve).with('cus_test123').and_return(double('Stripe::Customer', id: 'cus_test123'))
    end

    it 'creates a checkout session with correct parameters' do
      expect(Stripe::Checkout::Session).to receive(:create).with(
        hash_including(
          customer: 'cus_test123',
          mode: 'subscription',
          success_url: success_url,
          cancel_url: cancel_url
        )
      ).and_return(stripe_checkout_session)

      result = described_class.create_checkout_session(
        user: user,
        plan: plan,
        success_url: success_url,
        cancel_url: cancel_url
      )

      expect(result).to eq(stripe_checkout_session)
    end

    it 'includes plan details in line items' do
      expect(Stripe::Checkout::Session).to receive(:create).with(
        hash_including(
          line_items: array_including(
            hash_including(
              price_data: hash_including(
                unit_amount: 2500,
                currency: 'usd'
              )
            )
          )
        )
      ).and_return(stripe_checkout_session)

      described_class.create_checkout_session(
        user: user,
        plan: plan,
        success_url: success_url,
        cancel_url: cancel_url
      )
    end

    it 'creates customer if user does not have one' do
      user.update(stripe_customer_id: nil)

      expect(described_class).to receive(:create_customer).with(user).and_return('cus_new123')
      expect(Stripe::Checkout::Session).to receive(:create).with(
        hash_including(customer: 'cus_new123')
      ).and_return(stripe_checkout_session)

      described_class.create_checkout_session(
        user: user,
        plan: plan,
        success_url: success_url,
        cancel_url: cancel_url
      )
    end
  end

  describe '.attach_payment_method' do
    let(:payment_method_id) { 'pm_test123' }

    before do
      user.update(stripe_customer_id: 'cus_test123')
      allow(Stripe::Customer).to receive(:retrieve).with('cus_test123').and_return(double('Stripe::Customer', id: 'cus_test123'))
      allow(stripe_payment_method).to receive(:attach)
    end

    it 'attaches payment method to customer' do
      expect(Stripe::PaymentMethod).to receive(:attach).with(
        payment_method_id,
        { customer: 'cus_test123' }
      ).and_return(stripe_payment_method)

      described_class.attach_payment_method(
        user: user,
        payment_method_id: payment_method_id
      )
    end

    it 'saves payment method to database' do
      allow(Stripe::PaymentMethod).to receive(:attach).and_return(stripe_payment_method)

      expect {
        described_class.attach_payment_method(
          user: user,
          payment_method_id: payment_method_id
        )
      }.to change(user.payment_methods, :count).by(1)

      pm = user.payment_methods.last
      expect(pm.stripe_payment_method_id).to eq('pm_test123')
      expect(pm.card_brand).to eq('visa')
      expect(pm.last_four).to eq('4242')
    end

    it 'sets as default when requested' do
      allow(Stripe::PaymentMethod).to receive(:attach).and_return(stripe_payment_method)

      expect(Stripe::Customer).to receive(:update).with(
        'cus_test123',
        hash_including(
          invoice_settings: { default_payment_method: payment_method_id }
        )
      )

      described_class.attach_payment_method(
        user: user,
        payment_method_id: payment_method_id,
        set_as_default: true
      )

      expect(user.payment_methods.last.is_default).to be true
    end
  end

  describe '.detach_payment_method' do
    let(:payment_method_id) { 'pm_test123' }

    it 'detaches payment method from Stripe' do
      expect(Stripe::PaymentMethod).to receive(:detach).with(payment_method_id)

      described_class.detach_payment_method(payment_method_id)
    end

    it 'raises StripeError on failure' do
      allow(Stripe::PaymentMethod).to receive(:detach).and_raise(
        Stripe::InvalidRequestError.new('Not found', 'id')
      )

      expect {
        described_class.detach_payment_method(payment_method_id)
      }.to raise_error(StripeService::StripeError)
    end
  end

  describe '.cancel_subscription' do
    let(:subscription_id) { 'sub_test123' }

    it 'cancels at period end by default' do
      expect(Stripe::Subscription).to receive(:update).with(
        subscription_id,
        cancel_at_period_end: true
      )

      described_class.cancel_subscription(subscription_id)
    end

    it 'cancels immediately when requested' do
      expect(Stripe::Subscription).to receive(:cancel).with(subscription_id)

      described_class.cancel_subscription(subscription_id, cancel_at_period_end: false)
    end
  end

  describe '.pause_subscription' do
    let(:subscription_id) { 'sub_test123' }

    it 'pauses the subscription' do
      expect(Stripe::Subscription).to receive(:update).with(
        subscription_id,
        pause_collection: { behavior: 'void' }
      )

      described_class.pause_subscription(subscription_id)
    end
  end

  describe '.resume_subscription' do
    let(:subscription_id) { 'sub_test123' }

    it 'resumes the subscription' do
      expect(Stripe::Subscription).to receive(:update).with(
        subscription_id,
        pause_collection: ''
      )

      described_class.resume_subscription(subscription_id)
    end
  end

  describe '.create_product_checkout_session' do
    let(:product1) { create(:product, name: 'Ethiopian Yirgacheffe', price_cents: 1800) }
    let(:product2) { create(:product, name: 'Colombian Supremo', price_cents: 1600) }
    let(:cart_items) do
      [
        { product: product1, quantity: 2 },
        { product: product2, quantity: 1 }
      ]
    end
    let(:success_url) { 'https://example.com/shop/success' }
    let(:cancel_url) { 'https://example.com/shop/checkout' }
    let(:metadata) { { order_note: 'Test order' } }

    before do
      allow(Stripe::Customer).to receive(:create).and_return(stripe_customer)
      allow(Stripe::Checkout::Session).to receive(:create).and_return(stripe_checkout_session)
    end

    it 'creates a checkout session for one-time payment' do
      expect(Stripe::Checkout::Session).to receive(:create).with(
        hash_including(
          customer: stripe_customer.id,
          mode: 'payment',
          payment_method_types: [ 'card' ],
          success_url: success_url,
          cancel_url: cancel_url
        )
      )

      described_class.create_product_checkout_session(
        user: user,
        cart_items: cart_items,
        success_url: success_url,
        cancel_url: cancel_url,
        metadata: metadata
      )
    end

    it 'creates line items for each cart item' do
      expect(Stripe::Checkout::Session).to receive(:create) do |params|
        expect(params[:line_items].length).to eq(2)

        # Check first item
        first_item = params[:line_items][0]
        expect(first_item[:price_data][:product_data][:name]).to eq('Ethiopian Yirgacheffe')
        expect(first_item[:price_data][:unit_amount]).to eq(1800)
        expect(first_item[:quantity]).to eq(2)

        # Check second item
        second_item = params[:line_items][1]
        expect(second_item[:price_data][:product_data][:name]).to eq('Colombian Supremo')
        expect(second_item[:price_data][:unit_amount]).to eq(1600)
        expect(second_item[:quantity]).to eq(1)

        stripe_checkout_session
      end

      described_class.create_product_checkout_session(
        user: user,
        cart_items: cart_items,
        success_url: success_url,
        cancel_url: cancel_url
      )
    end

    it 'includes user_id and order_type in metadata' do
      expect(Stripe::Checkout::Session).to receive(:create) do |params|
        expect(params[:metadata][:user_id]).to eq(user.id)
        expect(params[:metadata][:order_type]).to eq('one_time')
        stripe_checkout_session
      end

      described_class.create_product_checkout_session(
        user: user,
        cart_items: cart_items,
        success_url: success_url,
        cancel_url: cancel_url
      )
    end

    it 'enables shipping address collection' do
      expect(Stripe::Checkout::Session).to receive(:create) do |params|
        expect(params[:shipping_address_collection]).to be_present
        expect(params[:shipping_address_collection][:allowed_countries]).to eq([ 'US' ])
        stripe_checkout_session
      end

      described_class.create_product_checkout_session(
        user: user,
        cart_items: cart_items,
        success_url: success_url,
        cancel_url: cancel_url
      )
    end

    it 'returns the checkout session' do
      session = described_class.create_product_checkout_session(
        user: user,
        cart_items: cart_items,
        success_url: success_url,
        cancel_url: cancel_url
      )

      expect(session).to eq(stripe_checkout_session)
    end

    context 'when user does not have a Stripe customer ID' do
      it 'creates a new Stripe customer' do
        expect(Stripe::Customer).to receive(:create).with(
          hash_including(
            email: user.email,
            name: user.full_name
          )
        ).and_return(stripe_customer)

        described_class.create_product_checkout_session(
          user: user,
          cart_items: cart_items,
          success_url: success_url,
          cancel_url: cancel_url
        )
      end
    end

    context 'when Stripe API fails' do
      before do
        allow(Stripe::Checkout::Session).to receive(:create)
          .and_raise(Stripe::StripeError.new('API Error'))
      end

      it 'raises a StripeService::StripeError' do
        expect {
          described_class.create_product_checkout_session(
            user: user,
            cart_items: cart_items,
            success_url: success_url,
            cancel_url: cancel_url
          )
        }.to raise_error(StripeService::StripeError, /Failed to create product checkout session/)
      end
    end
  end
end
