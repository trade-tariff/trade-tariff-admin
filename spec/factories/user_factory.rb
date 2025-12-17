FactoryBot.define do
  factory :user do
    sequence(:uid) { |n| n }
    email          { "user#{uid}@example.com" }
    name           { "User#{uid}" }

    after(:create) do |user|
      # Remove default GUEST role if a specific role trait is being used
      if user.roles.any? && user.roles.first.name == User::GUEST
        user.remove_role(User::GUEST)
      end
    end

    trait :gds_editor do
      after(:create) do |user|
        user.remove_role(user.current_role) if user.current_role
        user.add_role(User::TECHNICAL_OPERATOR)
      end
    end

    trait :hmrc_editor do
      after(:create) do |user|
        user.remove_role(user.current_role) if user.current_role
        user.add_role(User::TECHNICAL_OPERATOR)
      end
    end

    trait :hmrc_admin do
      after(:create) do |user|
        user.remove_role(user.current_role) if user.current_role
        user.add_role(User::TECHNICAL_OPERATOR)
      end
    end

    trait :technical_operator do
      after(:create) do |user|
        user.remove_role(user.current_role) if user.current_role
        user.add_role(User::TECHNICAL_OPERATOR)
      end
    end

    trait :hmrc_admin_role do
      after(:create) do |user|
        user.remove_role(user.current_role) if user.current_role
        user.add_role(User::HMRC_ADMIN)
      end
    end

    trait :auditor do
      after(:create) do |user|
        user.remove_role(user.current_role) if user.current_role
        user.add_role(User::AUDITOR)
      end
    end

    trait :guest do
      # Guest is the default, so no action needed
    end
  end
end
