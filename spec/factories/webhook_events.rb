FactoryBot.define do
  factory :webhook_event do
    stripe_event_id { "MyString" }
    event_type { "MyString" }
    processed_at { "2025-12-04 21:16:21" }
  end
end
