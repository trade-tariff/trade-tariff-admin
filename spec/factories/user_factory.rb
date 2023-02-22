FactoryBot.define do
  factory :user do
    sequence(:uid) { |n| n }
    email          { "user#{uid}@example.com" }
    name           { "User#{uid}" }

    trait :gds_editor do
      permissions { [User::Permissions::GDS_EDITOR] }
    end

    trait :hmrc_editor do
      permissions { [User::Permissions::SIGNIN, User::Permissions::HMRC_EDITOR] }
    end

    trait :full_access do
      permissions { [User::Permissions::SIGNIN, User::Permissions::FULL_ACCESS] }
    end
  end
end
