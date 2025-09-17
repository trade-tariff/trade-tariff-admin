FactoryBot.define do
  factory :exemption, class: "GreenLanes::Exemption" do
    sequence(:resource_id) { |n| n }
    code { "P#{resource_id}" }
    description { "pseudo exemptions" }
  end
end
