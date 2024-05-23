FactoryBot.define do
  factory :green_lanes_measure, class: 'GreenLanes::Measure' do
    sequence(:id) { |n| n }
    productline_suffix { '80' }
    category_assessment {}
    goods_nomenclature {}

    trait :with_category_assessment do
      association :category_assessment, factory: :category_assessment, strategy: :build
    end

    trait :with_goods_nomenclature do
      association :goods_nomenclature, factory: :green_lanes_goods_nomenclature, strategy: :build
    end
  end
end
