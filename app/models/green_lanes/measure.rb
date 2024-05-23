module GreenLanes
  class Measure
    include Her::JsonApi::Model
    use_api Her::XI_API
    extend HerPaginatable

    attributes :productline_suffix

    has_one :category_assessment
    has_one :goods_nomenclature

    collection_path '/admin/green_lanes/measures'
  end
end
