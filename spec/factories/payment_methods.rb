FactoryBot.define do
  factory :payment_method do
    user { nil }
    stripe_payment_method_id { "MyString" }
    card_brand { "MyString" }
    last_four { "MyString" }
    exp_month { 1 }
    exp_year { 1 }
    is_default { false }
  end
end
