class GoodsNomenclatureLabel
  include ApiEntity

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
             :has_self_text

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
    return "Very High" if value >= 0.85
    return "High" if value >= 0.5
    return "Medium" if value >= 0.3

    "Low"
  end

  def score_tag_colour(value = description_score)
    return "grey" if value.nil?
    return "green" if value >= 0.85
    return "blue" if value >= 0.5
    return "yellow" if value >= 0.3

    "grey"
  end

  # Store goods_nomenclature_id for path building
  attr_accessor :goods_nomenclature_id

  def to_param
    goods_nomenclature_id || goods_nomenclature_item_id
  end

  def self.listing(params)
    records = all(
      page: params[:page] || 1,
      type: params[:type] || "commodity",
      sort: params[:sort] || "score",
      direction: params[:direction] || "asc",
      status: params[:status],
      score_category: params[:score_category],
      q: params[:q],
    )

    {
      data: records.map(&:as_listing_json),
      pagination: pagination_for(records),
    }
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch labels: #{e.message}")
    { data: [], pagination: { page: 1, per_page: 20, total_count: 0, total_pages: 0 } }
  end

  def as_listing_json
    {
      goods_nomenclature_sid: goods_nomenclature_sid,
      goods_nomenclature_item_id: goods_nomenclature_item_id,
      score: score,
      stale: stale,
      manually_edited: manually_edited,
      description: original_description.to_s.truncate(80),
    }
  end

  def self.text_to_array(text)
    return [] if text.blank?

    text.split(/[\r\n]+/).map(&:strip).reject(&:blank?)
  end

private

  def text_to_array(text)
    self.class.text_to_array(text)
  end
end
