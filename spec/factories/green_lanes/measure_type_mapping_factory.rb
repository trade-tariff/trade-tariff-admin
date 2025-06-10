FactoryBot.define do
  factory :measure_type_mapping, class: 'GreenLanes::MeasureTypeMapping' do
    sequence(:resource_id) { |n| n }
    measure_type_id { resource_id }
    theme_id { 1 }
  end
end
