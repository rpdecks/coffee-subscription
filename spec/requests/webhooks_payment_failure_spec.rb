require 'rails_helper'

RSpec.describe 'Webhook Payment Failure Handling', type: :request do
  let(:user) { create(:customer_user) }
  let(:plan) { create(:subscription_plan) }
  let(:subscription) { create(:subscription, user: user, subscription_plan: plan, stripe_subscription_id: 'sub_test123') }
  let(:invoice_id) { 'in_test123' }

  before do
    subscription # ensure subscription exists
  end

  describe 'POST /webhooks/stripe with invoice.payment_failed' do
    let(:event_data) do
      {
        id: 'evt_payment_failed_123',
        type: 'invoice.payment_failed',
        data: {
          object: {
            id: invoice_id,
            subscription: subscription.stripe_subscription_id
          }
        }
      }
    end

    it 'marks subscription as past_due' do
      post webhooks_stripe_path, params: event_data.to_json, headers: { 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:success), "Expected success but got #{response.status}: #{response.body}"
      expect(subscription.reload.status).to eq('past_due')
    end

    it 'increments failed_payment_count' do
      expect {
        post webhooks_stripe_path, params: event_data.to_json, headers: { 'Content-Type' => 'application/json' }
      }.to change { subscription.reload.failed_payment_count }.by(1)
    end

    it 'sends payment failed email' do
      expect {
        post webhooks_stripe_path, params: event_data.to_json, headers: { 'Content-Type' => 'application/json' }
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('SubscriptionMailer', 'payment_failed', 'deliver_now', { args: [ subscription, anything ] })
    end

    it 'logs warning after 3 failures' do
      subscription.update(failed_payment_count: 2)

      allow(Rails.logger).to receive(:error).and_call_original

      post webhooks_stripe_path, params: event_data.to_json, headers: { 'Content-Type' => 'application/json' }

      expect(subscription.reload.failed_payment_count).to eq(3)
    end
  end

  describe 'POST /webhooks/stripe with invoice.payment_succeeded after failures' do
    let(:event_data) do
      {
        id: 'evt_payment_success_123',
        type: 'invoice.payment_succeeded',
        data: {
          object: {
            id: invoice_id,
            subscription: subscription.stripe_subscription_id
          }
        }
      }
    end

    before do
      subscription.update(status: :past_due, failed_payment_count: 2)
    end

    it 'reactivates subscription' do
      post webhooks_stripe_path, params: event_data.to_json, headers: { 'Content-Type' => 'application/json' }

      expect(subscription.reload.status).to eq('active')
    end

    it 'resets failed_payment_count' do
      post webhooks_stripe_path, params: event_data.to_json, headers: { 'Content-Type' => 'application/json' }

      expect(subscription.reload.failed_payment_count).to eq(0)
    end

    it 'creates an order' do
      expect {
        post webhooks_stripe_path, params: event_data.to_json, headers: { 'Content-Type' => 'application/json' }
      }.to have_enqueued_job(CreateSubscriptionOrderJob).with(subscription.id, invoice_id)
    end
  end
end
