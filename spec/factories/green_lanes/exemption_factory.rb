FactoryBot.define do
  factory :exemption, class: 'GreenLanes::Exemption' do
    sequence(:id) { |n| n }
    code { "P#{id}" }
    description { 'pseudo exemptions' }
  end
end
