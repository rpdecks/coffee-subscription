FactoryBot.define do
  factory :subscription do
    association :user
    association :subscription_plan
    status { :active }
    stripe_subscription_id { nil }
    current_period_start { nil }
    current_period_end { nil }
    next_delivery_date { 7.days.from_now.to_date }
    quantity { 1 }
    shipping_address_id { nil }
    payment_method_id { nil }

    trait :active do
      status { :active }
    end

    trait :paused do
      status { :paused }
    end

    trait :cancelled do
      status { :cancelled }
      cancelled_at { 1.day.ago }
    end
  end
end
