FactoryBot.define do
  factory :order_item do
    order { nil }
    product { nil }
    quantity { 1 }
    price_cents { 1 }
    grind_type { 1 }
    special_instructions { "MyText" }
  end
end
