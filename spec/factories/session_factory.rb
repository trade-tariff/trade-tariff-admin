FactoryBot.define do
  factory :session do
    association :user
    sequence(:token) { |n| "session-token-#{n}" }
    id_token { "encoded-id-token" }
    raw_info { { "sub" => user.uid, "email" => user.email } }

    trait :expired do
      expires_at { 1.hour.ago }
    end

    trait :current do
      expires_at { 1.hour.from_now }
    end
  end
end
