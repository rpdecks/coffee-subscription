FactoryBot.define do
  factory :subscription_plan do
    name { "MyString" }
    description { "MyText" }
    frequency { 1 }
    bags_per_delivery { 1 }
    price_cents { 1 }
    stripe_plan_id { "MyString" }
    active { false }
  end
end
