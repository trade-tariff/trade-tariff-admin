FactoryBot.define do
  factory :user do
    sequence(:uid) { |n| n }
    email          { "user#{uid}@example.com" }
    name           { "User#{uid}" }

    # Default user has GUEST role (assigned by User model before_create callback)
    # No need to remove it - GUEST is the valid default

    trait :technical_operator do
      after(:create) do |user|
        user.set_role(User::TECHNICAL_OPERATOR)
      end
    end

    trait :hmrc_admin do
      after(:create) do |user|
        user.set_role(User::HMRC_ADMIN)
      end
    end

    trait :auditor do
      after(:create) do |user|
        user.set_role(User::AUDITOR)
      end
    end

    trait :guest do
      after(:create) do |user|
        # Ensure user has GUEST role (explicitly set it to guarantee it exists)
        user.set_role(User::GUEST) unless user.guest?
      end
    end
  end
end
