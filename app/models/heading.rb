require 'heading/search_reference'

class Heading
  include ApiEntity

  attribute :goods_nomenclature_item_id

  has_many :commodities
  has_one :chapter

  def search_references
    Heading::SearchReference.all(casted_by: self)
  end

  def heading_id
    goods_nomenclature_item_id&.first(4)
  end

  def chapter_id
    chapter.short_code
  end

  def to_param
    heading_id.to_s.presence || resource_id
  end

  def reference_title
    "heading #{heading_id}: #{description}"
  end
end
