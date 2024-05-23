FactoryBot.define do
  factory :category_assessment, class: 'GreenLanes::CategoryAssessment' do
    sequence(:id) { |n| n }
    measure_type_id { '464' }
    regulation_id { 'R9700880' }
    regulation_role { '3' }
    theme_id { '1' }
    created_at { 2.days.ago.to_date }
    updated_at { nil }

    trait :with_theme do
      association :green_lanes_theme, strategy: :build

      theme_id { green_lanes_theme.id }
    end
  end
end
