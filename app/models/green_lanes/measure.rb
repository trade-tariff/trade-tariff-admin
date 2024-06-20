module GreenLanes
  class Measure
    include Her::JsonApi::Model
    use_api Her::XI_API
    extend HerPaginatable

    attributes :productline_suffix, :goods_nomenclature_item_id, :category_assessment_id

    has_one :category_assessment
    has_one :goods_nomenclature

    validates :productline_suffix, presence: true
    validates :goods_nomenclature_item_id, presence: true

    collection_path '/admin/green_lanes/measures'

    def initialize(attributes = {})
      super
      @has_goods_nomenclature = attributes[:goods_nomenclature].present?
    end

    attr_reader :has_goods_nomenclature
  end
end
