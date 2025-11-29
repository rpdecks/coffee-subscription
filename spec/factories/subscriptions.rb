FactoryBot.define do
  factory :subscription do
    user { nil }
    subscription_plan { nil }
    status { 1 }
    stripe_subscription_id { "MyString" }
    current_period_start { "2025-11-29 14:56:30" }
    current_period_end { "2025-11-29 14:56:30" }
    next_delivery_date { "2025-11-29" }
    shipping_address_id { 1 }
    payment_method_id { 1 }
  end
end
