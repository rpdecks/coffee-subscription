FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Coffee Product #{n}" }
    description { "A delicious coffee with notes of chocolate and caramel" }
    product_type { :coffee }
    roast_type { :signature }
    price_cents { 1800 }
    weight_oz { 12 }
    inventory_count { 100 }
    active { true }
    visible_in_shop { true }
    stripe_product_id { nil }
    stripe_price_id { nil }

    trait :coffee do
      product_type { :coffee }
      roast_type { :signature }
    end

    trait :light_roast do
      roast_type { :light }
    end

    trait :medium_roast do
      roast_type { :medium }
    end

    trait :dark_roast do
      roast_type { :dark }
    end

    trait :merch do
      product_type { :merch }
      roast_type { nil }
      sequence(:name) { |n| "Merch Item #{n}" }
      description { "Coffee Co. merchandise" }
      price_cents { 1200 }
      weight_oz { nil }
    end

    trait :inactive do
      active { false }
    end
  end
end
