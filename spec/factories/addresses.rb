FactoryBot.define do
  factory :address do
    association :user
    address_type { :shipping }
    street_address { "123 Main St" }
    street_address_2 { nil }
    city { "Portland" }
    state { "OR" }
    zip_code { "97201" }
    country { "USA" }
    is_default { true }
    
    trait :shipping do
      address_type { :shipping }
    end
    
    trait :billing do
      address_type { :billing }
    end
  end
end
