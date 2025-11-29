FactoryBot.define do
  factory :product do
    name { "MyString" }
    description { "MyText" }
    product_type { 1 }
    price_cents { 1 }
    weight_oz { "9.99" }
    inventory_count { 1 }
    active { false }
    stripe_product_id { "MyString" }
    stripe_price_id { "MyString" }
  end
end
