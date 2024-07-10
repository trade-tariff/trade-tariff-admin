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
      attributes_for_list(:green_lanes_measure, 2).map do |measure_attributes|
        { attributes: measure_attributes }
      end
    end

    exemptions do
      attributes_for_list(:exemption, 2).map do |exemption_attributes|
        { attributes: exemption_attributes }
      end
    end

    trait :with_theme do
      theme { { attributes: attributes_for(:green_lanes_theme) } }
    end

    trait :with_measure_pagination do
      measure_pagination { { attributes: attributes_for(:measure_pagination) } }
    end
  end
end
