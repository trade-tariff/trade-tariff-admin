FactoryBot.define do
  factory :user do
    sequence(:uid) { |n| n }
    email          { "user#{uid}@example.com" }
    name           { "User#{uid}" }

    # Default user has GUEST role (assigned by User model before_create callback)
    # No need to remove it - GUEST is the valid default

    trait :technical_operator do
      role { User::TECHNICAL_OPERATOR }
    end

    trait :hmrc_admin do
      role { User::HMRC_ADMIN }
    end

    trait :auditor do
      role { User::AUDITOR }
    end

    trait :guest do
      role { User::GUEST }
    end
  end
end
