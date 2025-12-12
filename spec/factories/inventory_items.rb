FactoryBot.define do
  factory :inventory_item do
    association :product
    state { :green }
    quantity { 10.0 }
    lot_number { "LOT#{rand(1000..9999)}" }
    received_on { 1.week.ago.to_date }

    trait :green do
      state { :green }
      roasted_on { nil }
    end

    trait :roasted do
      state { :roasted }
      roasted_on { 3.days.ago.to_date }
      expires_on { 18.days.from_now.to_date }
    end

    trait :packaged do
      state { :packaged }
      roasted_on { 5.days.ago.to_date }
    end

    trait :low_stock do
      quantity { 3.0 }
    end

    trait :out_of_stock do
      quantity { 0.0 }
    end

    trait :expiring_soon do
      expires_on { 7.days.from_now.to_date }
    end

    trait :fresh do
      roasted_on { 5.days.ago.to_date }
    end

    trait :aging do
      roasted_on { 30.days.ago.to_date }
    end
  end
end
