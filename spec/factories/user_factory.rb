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

    trait :hmrc_admin do
      permissions { [User::Permissions::SIGNIN, User::Permissions::HMRC_ADMIN] }
    end
  end
end
