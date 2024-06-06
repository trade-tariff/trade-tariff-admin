FactoryBot.define do
  factory :category_assessment, class: 'GreenLanes::CategoryAssessment' do
    sequence(:id) { |n| n }
    measure_type_id { '464' }
    regulation_id { 'R9700880' }
    regulation_role { '3' }
    theme_id { '1' }
    created_at { 2.days.ago.to_date }
    updated_at { nil }

    green_lanes_measures do
      attributes_for_list :green_lanes_measure, 2
    end

    exemptions do
      attributes_for_list :exemption, 2
    end

    trait :with_theme do
      association :green_lanes_theme, strategy: :build

      theme_id { green_lanes_theme.id }
    end

    trait :with_green_lanes_measures do
      association :green_lanes_measures, factory: :green_lanes_measure, strategy: :build
    end

    trait :with_exemptions do
      association :exemptions, factory: :exemption, strategy: :build
    end
  end
end
