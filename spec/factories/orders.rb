FactoryBot.define do
  factory :order do
    association :user
    association :subscription
    association :shipping_address, factory: :address
    sequence(:order_number) { |n| "ORD-2025-#{n.to_s.rjust(4, '0')}" }
    order_type { :subscription }
    status { :pending }
    subtotal_cents { 1800 }
    shipping_cents { 500 }
    tax_cents { 144 }
    total_cents { 2444 }
    stripe_payment_intent_id { nil }
    payment_method_id { nil }
    shipped_at { nil }
    delivered_at { nil }
    
    trait :pending do
      status { :pending }
    end
    
    trait :processing do
      status { :processing }
    end
    
    trait :roasting do
      status { :roasting }
    end
    
    trait :shipped do
      status { :shipped }
      shipped_at { 2.days.ago }
    end
    
    trait :delivered do
      status { :delivered }
      shipped_at { 7.days.ago }
      delivered_at { 3.days.ago }
    end
    
    trait :one_time do
      order_type { :one_time }
      subscription { nil }
    end
  end
end
