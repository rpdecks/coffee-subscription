FactoryBot.define do
  factory :coffee_preference do
    user { nil }
    roast_level { 1 }
    grind_type { 1 }
    flavor_notes { "MyText" }
    special_instructions { "MyText" }
  end
end
