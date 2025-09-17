FactoryBot.define do
  factory :green_lanes_goods_nomenclature, class: "GreenLanes::GoodsNomenclature" do
    sequence(:resource_id) { |n| n }
    sequence(:goods_nomenclature_item_id) { |n| n }
    description { "Some description" }
  end
end
