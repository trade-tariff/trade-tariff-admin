require 'commodity/search_reference'

class Commodity
  include Her::JsonApi::Model

  collection_path '/admin/commodities'

  attributes :id, :description

  has_many :search_references, class_name: 'Commodity::SearchReference'

  def productline_suffix
    id.split('-', 2).last
  end

  def goods_nomenclature_item_id
    id.split('-', 2).first
  end

  def heading_id
    goods_nomenclature_item_id.first(4)
  end

  def export_filename
    "#{self.class.name.tableize}-#{id}-synonyms-#{Time.zone.now.iso8601}.csv"
  end

  def reference_title
    "Commodity (#{goods_nomenclature_item_id})"
  end

  def request_path(_opts = {})
    self.class.build_request_path("/admin/commodities/#{to_param}", attributes.dup)
  end
end
