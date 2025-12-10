FactoryBot.define do
  factory :payment_method do
    user { nil }
    stripe_payment_method_id { "pm_#{SecureRandom.hex(12)}" }
    card_brand { "Visa" }
    last_four { "4242" }
    exp_month { 12 }
    exp_year { Time.current.year + 2 }
    is_default { false }
  end
end
