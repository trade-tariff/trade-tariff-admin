class GoodsNomenclatureLabel
  include ApiEntity
  include GeneratedContentResource

  set_singular_path "admin/goods_nomenclatures/:goods_nomenclature_id/goods_nomenclature_label"

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
             :original_description,
             :has_self_text,
             :needs_review,
             :approved,
             :expired,
             :created_at,
             :updated_at

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

  def to_param
    goods_nomenclature_id || goods_nomenclature_item_id
  end

  def self.text_to_array(text)
    return [] if text.blank?

    text.split(/[\r\n]+/).map(&:strip).reject(&:blank?)
  end

private

  def generated_content_member_path
    "admin/goods_nomenclatures/#{to_param}/goods_nomenclature_label"
  end

  def listing_description
    original_description
  end

  def listing_description_key
    :description
  end

  def score_value_for_tags
    description_score
  end

  def text_to_array(text)
    self.class.text_to_array(text)
  end
end
