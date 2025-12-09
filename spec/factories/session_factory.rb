FactoryBot.define do
  factory :session do
    association :user
    sequence(:token) { |n| "session-token-#{n}" }
    id_token { "encoded-id-token" }
    raw_info { { "sub" => user.uid, "email" => user.email } }
  end
end
