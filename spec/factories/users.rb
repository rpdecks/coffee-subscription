FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { "John" }
    last_name { "Doe" }
    phone { "555-123-4567" }
    role { :customer }
    
    trait :admin do
      role { :admin }
      sequence(:email) { |n| "admin#{n}@example.com" }
    end
    
    trait :customer do
      role { :customer }
    end
    
    factory :admin_user, traits: [:admin]
    factory :customer_user, traits: [:customer]
  end
end
