FactoryBot.define do
  factory :exemption, class: 'GreenLanes::Exemption' do
    sequence(:id) { |n| n }
    code { 'P' }
    description { 'pseudo exemptions' }
    created_at { 2.days.ago.to_date }
    updated_at { nil }
  end
end
