FactoryBot.define do
  factory :commodity do
    goods_nomenclature_item_id { 10.times.map { Random.rand(1..9) }.join }
    producline_suffix { 80 }

    trait :with_heading do
      heading { attributes_for(:heading) }

      heading_id { heading[:goods_nomenclature_item_id].first(4) }
    end
  end
end
