FactoryBot.define do
  factory :supplier do
    sequence(:name) { |n| "Supplier #{n}" }
    url { "https://example.com" }
    contact_name { "Jane Smith" }
    contact_email { "jane@example.com" }
    notes { "Reliable supplier" }

    trait :with_green_coffees do
      after(:create) do |supplier|
        create_list(:green_coffee, 3, supplier: supplier)
      end
    end
  end
end
