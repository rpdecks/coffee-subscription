FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { "John" }
    last_name { "Doe" }
    phone { "555-123-4567" }
    role { :customer }
    confirmed_at { Time.current }

    trait :admin do
      role { :admin }
      sequence(:email) { |n| "admin#{n}@example.com" }
    end

    trait :customer do
      role { :customer }
    end

    trait :unconfirmed do
      confirmed_at { nil }

      # Manually confirm token after create to avoid email send issues in tests
      before(:create) do |user|
        user.skip_confirmation_notification!
      end

      after(:create) do |user|
        user.update_columns(
          confirmation_token: Devise.friendly_token,
          confirmation_sent_at: Time.current
        )
      end
    end

    factory :admin_user, traits: [ :admin ]
    factory :customer_user, traits: [ :customer ]
  end
end
