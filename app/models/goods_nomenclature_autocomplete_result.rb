class GoodsNomenclatureAutocompleteResult
  include ApiEntity

  set_collection_path "admin/goods_nomenclature_autocomplete"

  attributes :goods_nomenclature_item_id, :description

  def truncated_description
    description.to_s.truncate(100)
  end

  def label
    [goods_nomenclature_item_id, truncated_description].compact.join(" - ")
  end

  def as_json(*)
    {
      id: resource_id,
      goods_nomenclature_item_id: goods_nomenclature_item_id,
      description: description,
      truncated_description: truncated_description,
      label: label,
    }
  end

  def self.listing(query, filters: {})
    all({ q: query, filter: filters }.compact).map(&:as_json)
  end

  def self.selected_listing(codes)
    Array(codes).filter_map do |code|
      match = all(q: code).to_a.detect do |result|
        result.goods_nomenclature_item_id.to_s.start_with?(code.to_s)
      end

      next if match.blank?

      match.as_json.slice(:goods_nomenclature_item_id, :truncated_description)
    end
  end
end
