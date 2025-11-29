FactoryBot.define do
  factory :address do
    user { nil }
    address_type { 1 }
    street_address { "MyString" }
    street_address_2 { "MyString" }
    city { "MyString" }
    state { "MyString" }
    zip_code { "MyString" }
    country { "MyString" }
    is_default { false }
  end
end
