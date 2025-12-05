require 'rails_helper'

RSpec.describe 'Webhook Subscription Lifecycle', type: :request do
  let(:user) { create(:customer_user) }
  let(:plan) { create(:subscription_plan) }
  let(:subscription) { create(:subscription, user: user, subscription_plan: plan, stripe_subscription_id: 'sub_test123') }

  before do
    subscription # ensure subscription exists
  end

  describe 'POST /webhooks/stripe with customer.subscription.updated' do
    it 'updates status to past_due' do
      event_data = {
        id: 'evt_sub_updated_1',
        type: 'customer.subscription.updated',
        data: {
          object: {
            id: subscription.stripe_subscription_id,
            customer: user.stripe_customer_id,
            status: 'past_due'
          }
        }
      }

      post webhooks_stripe_path, params: event_data.to_json, headers: { 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:success)
      expect(subscription.reload.status).to eq('past_due')
    end

    it 'updates status to cancelled' do
      event_data = {
        id: 'evt_sub_updated_2',
        type: 'customer.subscription.updated',
        data: {
          object: {
            id: subscription.stripe_subscription_id,
            customer: user.stripe_customer_id,
            status: 'canceled'
          }
        }
      }

      post webhooks_stripe_path, params: event_data.to_json, headers: { 'Content-Type' => 'application/json' }

      expect(subscription.reload.status).to eq('cancelled')
    end
  end

  describe 'POST /webhooks/stripe with customer.subscription.deleted' do
    it 'marks subscription as cancelled' do
      event_data = {
        id: 'evt_sub_deleted_1',
        type: 'customer.subscription.deleted',
        data: {
          object: {
            id: subscription.stripe_subscription_id,
            customer: user.stripe_customer_id
          }
        }
      }

      post webhooks_stripe_path, params: event_data.to_json, headers: { 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:success)
      expect(subscription.reload.status).to eq('cancelled')
      expect(subscription.cancelled_at).to be_present
    end

    it 'sends cancellation email' do
      event_data = {
        id: 'evt_sub_deleted_2',
        type: 'customer.subscription.deleted',
        data: {
          object: {
            id: subscription.stripe_subscription_id,
            customer: user.stripe_customer_id
          }
        }
      }

      expect {
        post webhooks_stripe_path, params: event_data.to_json, headers: { 'Content-Type' => 'application/json' }
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('SubscriptionMailer', 'subscription_cancelled', 'deliver_now', { args: [ subscription ] })
    end
  end
end
