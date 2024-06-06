FactoryBot.define do
  factory :green_lanes_measure, class: 'GreenLanes::Measure' do
    sequence(:id) { |n| n }
    productline_suffix { '80' }
    category_assessment {}
    goods_nomenclature {}

    trait :with_category_assessment do
      category_assessment { attributes_for(:category_assessment) }
    end

    trait :with_goods_nomenclature do
      goods_nomenclature { attributes_for(:green_lanes_goods_nomenclature) }
    end
  end
end
