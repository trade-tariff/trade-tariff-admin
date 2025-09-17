require "commodity/search_reference"

class Commodity
  include ApiEntity

  attributes :goods_nomenclature_item_id,
             :producline_suffix,
             :description,
             :declarable

  def search_references
    Commodity::SearchReference.all(casted_by: self)
  end

  def heading_id
    goods_nomenclature_item_id.first(4)
  end

  def reference_title
    "Commodity (#{goods_nomenclature_item_id})"
  end

  def to_param
    if goods_nomenclature_item_id && producline_suffix
      "#{goods_nomenclature_item_id}-#{producline_suffix}"
    else
      resource_id
    end
  end

  alias_method :declarable?, :declarable
end
