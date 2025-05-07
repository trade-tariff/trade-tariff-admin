module GreenLanes
  class Measure
    include ApiEntity

    attr_accessor :productline_suffix, :goods_nomenclature_item_id, :category_assessment_id

    has_one :category_assessment
    has_one :goods_nomenclature

    validates :productline_suffix, presence: true
    validates :goods_nomenclature_item_id, presence: true

    def has_goods_nomenclature?
      self[:goods_nomenclature].present?
    end
  end
end
