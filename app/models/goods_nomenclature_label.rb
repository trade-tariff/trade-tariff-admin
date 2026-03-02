class GoodsNomenclatureLabel
  include ApiEntity

  set_singular_path "admin/goods_nomenclatures/:goods_nomenclature_id/goods_nomenclature_label"
  set_collection_path "admin/goods_nomenclature_labels"

  attributes :goods_nomenclature_sid,
             :goods_nomenclature_item_id,
             :goods_nomenclature_type,
             :producline_suffix,
             :stale,
             :manually_edited,
             :context_hash,
             :labels,
             :description_score,
             :synonym_scores,
             :colloquial_term_scores,
             :score,
             :nomenclature_type,
             :original_description

  # Label field accessors - fall back to labels JSONB for singular (show) responses
  def original_description
    attributes[:original_description] || labels&.dig("original_description")
  end

  def description
    labels&.dig("description")
  end

  def known_brands
    labels&.dig("known_brands") || []
  end

  def colloquial_terms
    labels&.dig("colloquial_terms") || []
  end

  def synonyms
    labels&.dig("synonyms") || []
  end

  # Text conversion for form fields (array <-> newline-separated text)
  def known_brands_text
    known_brands.join("\n")
  end

  def known_brands_text=(text)
    self.labels ||= {}
    labels["known_brands"] = text_to_array(text)
  end

  def colloquial_terms_text
    colloquial_terms.join("\n")
  end

  def colloquial_terms_text=(text)
    self.labels ||= {}
    labels["colloquial_terms"] = text_to_array(text)
  end

  def synonyms_text
    synonyms.join("\n")
  end

  def synonyms_text=(text)
    self.labels ||= {}
    labels["synonyms"] = text_to_array(text)
  end

  def description=(value)
    self.labels ||= {}
    labels["description"] = value
  end

  def score_label(value = description_score)
    return "No score" if value.nil?
    return "Amazing" if value >= 0.85
    return "Good" if value >= 0.5
    return "Okay" if value >= 0.3

    "Bad"
  end

  def score_tag_colour(value = description_score)
    return "grey" if value.nil?
    return "blue" if value >= 0.85
    return "green" if value >= 0.5
    return "yellow" if value >= 0.3

    "red"
  end

  # Store goods_nomenclature_id for path building
  attr_accessor :goods_nomenclature_id

  def self.find(goods_nomenclature_id, opts = {})
    entity = new(goods_nomenclature_id: goods_nomenclature_id)
    path = entity.singular_path

    response = api.get(path, opts)
    parsed = parse_jsonapi(response)

    record = new(parsed)
    record.goods_nomenclature_id = goods_nomenclature_id
    record
  end

  def to_param
    goods_nomenclature_id || goods_nomenclature_item_id
  end

private

  def text_to_array(text)
    return [] if text.blank?

    text.split(/[\r\n]+/).map(&:strip).reject(&:blank?)
  end
end
