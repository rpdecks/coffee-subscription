FactoryBot.define do
  factory :roast_event do
    association :roast_session
    time_seconds { 120 }
    bean_temp_f { 300.0 }
    manifold_wc { 0.9 }
    air_position { :drum }
    event_type { nil }

    trait :charge do
      time_seconds { 0 }
      bean_temp_f { 400.0 }
      event_type { :charge }
    end

    trait :turning_point do
      time_seconds { 90 }
      bean_temp_f { 200.0 }
      event_type { :turning_point }
    end

    trait :first_crack_start do
      time_seconds { 540 }
      bean_temp_f { 395.0 }
      event_type { :first_crack_start }
    end

    trait :drop do
      time_seconds { 720 }
      bean_temp_f { 420.0 }
      event_type { :drop }
    end
  end
end
