class GoodsNomenclatureLabelStats
  include ApiEntity

  uk_only

  set_singular_path "admin/goods_nomenclature_labels/stats"

  attributes :total_goods_nomenclatures,
             :descriptions_count,
             :known_brands_count,
             :colloquial_terms_count,
             :synonyms_count,
             :ai_created_only,
             :human_edited

  def self.fetch
    response = api.get("admin/goods_nomenclature_labels/stats")
    parsed = parse_jsonapi(response)

    new(parsed)
  end
end
