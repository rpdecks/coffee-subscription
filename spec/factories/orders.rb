FactoryBot.define do
  factory :order do
    user { nil }
    subscription { nil }
    order_number { "MyString" }
    order_type { 1 }
    status { 1 }
    subtotal_cents { 1 }
    shipping_cents { 1 }
    tax_cents { 1 }
    total_cents { 1 }
    stripe_payment_intent_id { "MyString" }
    shipping_address_id { 1 }
    payment_method_id { 1 }
    shipped_at { "2025-11-29 14:58:06" }
    delivered_at { "2025-11-29 14:58:06" }
  end
end
