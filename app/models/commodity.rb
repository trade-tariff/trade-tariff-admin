require 'commodity/search_reference'

class Commodity
  include Her::JsonApi::Model

  collection_path '/admin/commodities'

  has_many :search_references, class_name: 'Commodity::SearchReference'

  def id
    to_param
  end

  def to_param
    goods_nomenclature_item_id
  end

  def heading_id
    goods_nomenclature_item_id.first(4)
  end

  def reference_title
    "Commodity (#{to_param})"
  end

  def request_path(_opts = {})
    self.class.build_request_path("/admin/commodities/#{to_param}", attributes.dup)
  end
end
