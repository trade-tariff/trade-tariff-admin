class GoodsNomenclatureLabelStats
  include ApiEntity

  uk_only

  set_singular_path "admin/goods_nomenclature_labels/stats"

  attributes :total_labels,
             :with_description,
             :with_known_brands,
             :with_colloquial_terms,
             :with_synonyms,
             :ai_created_only,
             :human_edited

  def self.fetch
    response = api.get("admin/goods_nomenclature_labels/stats")
    parsed = parse_jsonapi(response)

    new(parsed)
  end
end
