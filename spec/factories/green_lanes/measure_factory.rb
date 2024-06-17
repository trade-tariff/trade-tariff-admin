FactoryBot.define do
  factory :green_lanes_measure, class: 'GreenLanes::Measure' do
    sequence(:id) { |n| n }
    productline_suffix { '80' }
    goods_nomenclature_item_id { '8080658080' }
    category_assessment_id { '1' }
    category_assessment {}
    goods_nomenclature {}

    trait :with_category_assessment do
      category_assessment { { attributes: attributes_for(:category_assessment) } }
      # category_assessment_id { category_assessment.id }
    end

    trait :with_goods_nomenclature do
      goods_nomenclature { { attributes: attributes_for(:green_lanes_goods_nomenclature) } }
    end
  end
end
