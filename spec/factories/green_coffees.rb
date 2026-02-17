FactoryBot.define do
  factory :green_coffee do
    association :supplier
    sequence(:name) { |n| "Green Coffee #{n}" }
    origin_country { "Ethiopia" }
    region { "Yirgacheffe" }
    variety { "Heirloom" }
    process { "Washed" }
    harvest_date { 3.months.ago.to_date }
    arrived_on { 2.months.ago.to_date }
    cost_per_lb { 6.50 }
    quantity_lbs { 50.0 }
    lot_number { "GC#{rand(1000..9999)}" }
    notes { "Floral and citrus notes" }

    trait :fresh do
      harvest_date { 2.months.ago.to_date }
    end

    trait :good do
      harvest_date { 8.months.ago.to_date }
    end

    trait :aging do
      harvest_date { 11.months.ago.to_date }
    end

    trait :past_crop do
      harvest_date { 14.months.ago.to_date }
    end

    trait :out_of_stock do
      quantity_lbs { 0.0 }
    end

    trait :no_harvest_date do
      harvest_date { nil }
    end
  end
end
