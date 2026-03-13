FactoryBot.define do
  factory :customer_review do
    association :product
    customer_name { "Taylor" }
    location { "Portland, OR" }
    headline { "Exactly what I wanted" }
    body { "Fresh, balanced, and easy to look forward to every morning." }
    rating { 5 }
    approved { false }
    featured_on_about { false }
    sort_position { 0 }

    trait :approved do
      approved { true }
    end

    trait :featured_on_about do
      approved { true }
      featured_on_about { true }
    end

    trait :general do
      product { nil }
    end
  end
end
