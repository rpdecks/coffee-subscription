FactoryBot.define do
  factory :roast_session do
    coffee_name { "Ethiopia Yirgacheffe" }
    batch_size_g { 450 }
    process { "Washed" }
    gas_type { :lp }
    ambient_temp_f { 72.0 }
    charge_temp_target_f { 400.0 }
    started_at { Time.current }

    trait :with_lot do
      lot_id { "LOT-2026-001" }
    end

    trait :with_weights do
      green_weight_g { 450 }
      roasted_weight_g { 382 }
    end

    trait :completed do
      ended_at { Time.current + 12.minutes }
      total_roast_time_seconds { 720 }
    end

    trait :with_metrics do
      completed
      with_weights
      development_time_seconds { 90 }
      development_ratio { 12.5 }
      weight_loss_percent { 15.1 }
    end

    trait :with_events do
      after(:create) do |session|
        create(:roast_event, roast_session: session, time_seconds: 0, bean_temp_f: 400.0, manifold_wc: 1.0, event_type: :charge)
        create(:roast_event, roast_session: session, time_seconds: 90, bean_temp_f: 200.0, manifold_wc: 0.8, event_type: :turning_point)
        create(:roast_event, roast_session: session, time_seconds: 180, bean_temp_f: 280.0, manifold_wc: 0.9)
        create(:roast_event, roast_session: session, time_seconds: 360, bean_temp_f: 350.0, manifold_wc: 1.0, event_type: :yellow)
        create(:roast_event, roast_session: session, time_seconds: 540, bean_temp_f: 395.0, manifold_wc: 1.1, event_type: :first_crack_start)
        create(:roast_event, roast_session: session, time_seconds: 630, bean_temp_f: 410.0, manifold_wc: 1.0, event_type: :first_crack_rolling)
        create(:roast_event, roast_session: session, time_seconds: 660, bean_temp_f: 415.0, manifold_wc: 0.9, event_type: :first_crack_end)
        create(:roast_event, roast_session: session, time_seconds: 720, bean_temp_f: 420.0, manifold_wc: 0.8, event_type: :drop)
      end
    end
  end
end
