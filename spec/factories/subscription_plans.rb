FactoryBot.define do
  factory :subscription_plan do
    sequence(:name) { |n| "Plan #{n}" }
    description { "A great subscription plan" }
    frequency { :weekly }
    bags_per_delivery { 1 }
    price_cents { 1800 }
    stripe_plan_id { nil }
    active { true }
    
    trait :weekly do
      frequency { :weekly }
      name { "Weekly - 1 Bag" }
      bags_per_delivery { 1 }
      price_cents { 1800 }
    end
    
    trait :biweekly do
      frequency { :biweekly }
      name { "Bi-Weekly - 2 Bags" }
      bags_per_delivery { 2 }
      price_cents { 3400 }
    end
    
    trait :monthly do
      frequency { :monthly }
      name { "Monthly - 2 Bags" }
      bags_per_delivery { 2 }
      price_cents { 3200 }
    end
    
    trait :inactive do
      active { false }
    end
  end
end
