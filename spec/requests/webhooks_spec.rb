# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebhooksController, type: :request do
  let(:endpoint_secret) { 'whsec_test123' }

  before do
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :webhook_secret).and_return(endpoint_secret)
  end

  describe 'POST /webhooks/stripe' do
    let(:event_data) { { object: stripe_object } }
    let(:event) do
      double(
        'Stripe::Event',
        type: event_type,
        data: double(object: stripe_object)
      )
    end

    before do
      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
    end

    context 'checkout.session.completed event' do
      let(:event_type) { 'checkout.session.completed' }
      let(:user) { create(:customer_user, stripe_customer_id: 'cus_test123') }
      let(:plan) { create(:subscription_plan) }
      let!(:address) { create(:address, user: user) }
      let!(:payment_method) { create(:payment_method, user: user, is_default: true) }

      let(:stripe_object) do
        double(
          id: 'cs_test123',
          customer: 'cus_test123',
          subscription: 'sub_test123',
          metadata: {
            'user_id' => user.id.to_s,
            'subscription_plan_id' => plan.id.to_s,
            'bag_size' => '12oz',
            'frequency' => '30'
          }
        )
      end

      it 'creates a subscription' do
        expect {
          post '/webhooks/stripe', params: { type: event_type }, as: :json
        }.to change(Subscription, :count).by(1)

        subscription = Subscription.last
        expect(subscription.user).to eq(user)
        expect(subscription.subscription_plan).to eq(plan)
        expect(subscription.stripe_subscription_id).to eq('sub_test123')
        expect(subscription.bag_size).to eq('12oz')
        expect(subscription.status).to eq('active')
      end

      it 'returns success status' do
        post '/webhooks/stripe', params: { type: event_type }, as: :json

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['status']).to eq('success')
      end
    end

    context 'customer.subscription.updated event' do
      let(:event_type) { 'customer.subscription.updated' }
      let!(:subscription) { create(:subscription, :active, stripe_subscription_id: 'sub_test123') }

      let(:stripe_object) do
        double(
          id: 'sub_test123',
          status: 'canceled'
        )
      end

      it 'updates the subscription status' do
        post '/webhooks/stripe', params: { type: event_type }, as: :json

        expect(subscription.reload.status).to eq('cancelled')
      end
    end

    context 'customer.subscription.deleted event' do
      let(:event_type) { 'customer.subscription.deleted' }
      let!(:subscription) { create(:subscription, :active, stripe_subscription_id: 'sub_test123') }

      let(:stripe_object) do
        double(id: 'sub_test123')
      end

      it 'marks subscription as cancelled' do
        post '/webhooks/stripe', params: { type: event_type }, as: :json

        expect(subscription.reload.status).to eq('cancelled')
      end
    end

    context 'invoice.payment_succeeded event' do
      let(:event_type) { 'invoice.payment_succeeded' }
      let!(:subscription) { create(:subscription, :active, stripe_subscription_id: 'sub_test123') }

      let(:stripe_object) do
        double(
          id: 'in_test123',
          subscription: 'sub_test123'
        )
      end

      it 'enqueues order creation job' do
        expect(CreateSubscriptionOrderJob).to receive(:perform_later).with(subscription.id, 'in_test123')

        post '/webhooks/stripe', params: { type: event_type }, as: :json
      end
    end

    context 'invoice.payment_failed event' do
      let(:event_type) { 'invoice.payment_failed' }
      let!(:subscription) { create(:subscription, :active, stripe_subscription_id: 'sub_test123') }

      let(:stripe_object) do
        double(
          id: 'in_test123',
          subscription: 'sub_test123'
        )
      end

      it 'marks subscription as past_due' do
        post '/webhooks/stripe', params: { type: event_type }, as: :json

        expect(subscription.reload.status).to eq('past_due')
      end
    end

    context 'with invalid signature' do
      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise(
          Stripe::SignatureVerificationError.new('Invalid signature', 'sig_header')
        )
      end

      it 'returns bad request' do
        post '/webhooks/stripe', params: {}, as: :json

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'with unhandled event type' do
      let(:event_type) { 'some.unknown.event' }
      let(:stripe_object) { double }

      it 'returns success but logs the unhandled event' do
        expect(Rails.logger).to receive(:info).with(/Unhandled Stripe event type/)

        post '/webhooks/stripe', params: { type: event_type }, as: :json

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
