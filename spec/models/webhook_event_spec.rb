require 'rails_helper'

RSpec.describe WebhookEvent, type: :model do
  describe "creation" do
    it "can be created with a stripe_event_id" do
      event = WebhookEvent.create(stripe_event_id: "evt_test_123")
      expect(event).to be_persisted
      expect(event.stripe_event_id).to eq("evt_test_123")
    end

    it "prevents duplicate stripe_event_id processing" do
      WebhookEvent.create(stripe_event_id: "evt_test_456")
      expect {
        WebhookEvent.create!(stripe_event_id: "evt_test_456")
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe ".processed?" do
    it "returns true if stripe_event_id exists" do
      WebhookEvent.create(stripe_event_id: "evt_exists")
      expect(WebhookEvent.exists?(stripe_event_id: "evt_exists")).to be true
    end

    it "returns false if stripe_event_id does not exist" do
      expect(WebhookEvent.exists?(stripe_event_id: "evt_not_exists")).to be false
    end
  end
end
