require 'rails_helper'

RSpec.describe 'Webhook Idempotency', type: :request do
  let(:user) { create(:customer_user) }
  let(:plan) { create(:subscription_plan) }
  let(:subscription) { create(:subscription, user: user, subscription_plan: plan, stripe_subscription_id: 'sub_test123') }

  describe 'duplicate webhook events' do
    let(:event_data) do
      {
        id: 'evt_unique_123',
        type: 'customer.subscription.updated',
        data: {
          object: {
            id: subscription.stripe_subscription_id,
            customer: user.stripe_customer_id,
            status: 'active'
          }
        }
      }
    end

    it 'processes event only once' do
      # First request
      post webhooks_stripe_path, params: event_data.to_json, headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:success)
      
      first_webhook_event = WebhookEvent.find_by(stripe_event_id: 'evt_unique_123')
      expect(first_webhook_event).to be_present
      expect(first_webhook_event.processed_at).to be_present
      
      # Second request with same event ID
      post webhooks_stripe_path, params: event_data.to_json, headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['message']).to eq('Event already processed')
    end

    it 'creates WebhookEvent record' do
      expect {
        post webhooks_stripe_path, params: event_data.to_json, headers: { 'Content-Type' => 'application/json' }
      }.to change(WebhookEvent, :count).by(1)
      
      webhook_event = WebhookEvent.last
      expect(webhook_event.stripe_event_id).to eq('evt_unique_123')
      expect(webhook_event.event_type).to eq('customer.subscription.updated')
      expect(webhook_event.processed_at).to be_present
    end

    it 'does not duplicate processing side effects' do
      # Set subscription to a different status
      subscription.update(status: :cancelled)
      
      # First webhook should update status
      post webhooks_stripe_path, params: event_data.to_json, headers: { 'Content-Type' => 'application/json' }
      expect(subscription.reload.status).to eq('active')
      
      # Change status manually
      subscription.update(status: :paused)
      
      # Second webhook with same ID should not change status again
      post webhooks_stripe_path, params: event_data.to_json, headers: { 'Content-Type' => 'application/json' }
      expect(subscription.reload.status).to eq('paused')
    end
  end
end
