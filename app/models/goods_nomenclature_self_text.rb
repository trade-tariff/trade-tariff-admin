class GoodsNomenclatureSelfText
  include ApiEntity
  include RecordDateFormatting

  set_singular_path "admin/goods_nomenclatures/:goods_nomenclature_id/goods_nomenclature_self_text"

  attributes :goods_nomenclature_sid,
             :goods_nomenclature_item_id,
             :self_text,
             :generation_type,
             :input_context,
             :needs_review,
             :manually_edited,
             :stale,
             :approved,
             :expired,
             :created_at,
             :updated_at,
             :generated_at,
             :eu_self_text,
             :similarity_score,
             :coherence_score,
             :nomenclature_type,
             :score,
             :has_label

  attr_accessor :goods_nomenclature_id

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
    Rails.logger.error("Failed to fetch self-texts: #{e.message}")
    { data: [], pagination: { page: 1, per_page: 20, total_count: 0, total_pages: 0 } }
  end

  def as_listing_json
    {
      goods_nomenclature_sid: goods_nomenclature_sid,
      goods_nomenclature_item_id: goods_nomenclature_item_id,
      score: score,
      needs_review: needs_review,
      stale: stale,
      manually_edited: manually_edited,
      approved: approved,
      expired: expired,
      self_text: self_text.to_s.truncate(80),
    }
  end

  def to_param
    goods_nomenclature_sid&.to_s || goods_nomenclature_id
  end

  def generate_score
    api.post("admin/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text/score")
  end

  def regenerate
    api.post("admin/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text/regenerate")
  end

  def approve
    api.post("admin/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text/approve")
  end

  def reject
    api.post("admin/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text/reject")
  end

  def combined_score
    if similarity_score && coherence_score
      (similarity_score + coherence_score) / 2.0
    else
      similarity_score || coherence_score
    end
  end

  def score_kind
    if similarity_score && coherence_score
      "Combined"
    elsif similarity_score
      "Similarity"
    elsif coherence_score
      "Coherence"
    end
  end

  def score_label(value = combined_score)
    return "No score" if value.nil?
    return "Very High" if value >= 0.85
    return "High" if value >= 0.5
    return "Medium" if value >= 0.3

    "Low"
  end

  def score_tag_colour(value = combined_score)
    return "grey" if value.nil?
    return "green" if value >= 0.85
    return "blue" if value >= 0.5
    return "yellow" if value >= 0.3

    "grey"
  end

  def ancestor_chain
    return [] unless input_context.is_a?(Hash)

    (input_context["ancestors"] || []).map do |a|
      desc = a["description"].to_s
      if desc.match?(/\bother\b/i) && a["self_text"]
        a["self_text"]
      else
        desc
      end
    end
  end

  def kind
    return nil unless input_context.is_a?(Hash)

    input_context["goods_nomenclature_class"]
  end

  def context_description
    return nil unless input_context.is_a?(Hash)

    input_context["description"]
  end

  def context_siblings
    return [] unless input_context.is_a?(Hash)

    input_context["siblings"] || []
  end
end
