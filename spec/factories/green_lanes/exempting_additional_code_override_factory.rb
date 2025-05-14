FactoryBot.define do
  factory :exempting_additional_code_override, class: 'GreenLanes::ExemptingAdditionalCodeOverride' do
    sequence(:resource_id) { |n| n }
    additional_code_type_id { 'C' }
    additional_code { '499' }
    created_at { 2.days.ago.to_date }
    updated_at { nil }
  end
end
