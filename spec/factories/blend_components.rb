FactoryBot.define do
  factory :blend_component do
    association :product
    association :green_coffee
    percentage { 100.0 }

    trait :half do
      percentage { 50.0 }
    end

    trait :quarter do
      percentage { 25.0 }
    end
  end
end
