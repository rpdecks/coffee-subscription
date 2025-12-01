FactoryBot.define do
  factory :order_item do
    association :order
    association :product
    quantity { 1 }
    price_cents { 1800 }
    grind_type { :whole_bean }
    special_instructions { nil }
  end
end
