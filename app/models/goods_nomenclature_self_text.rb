class GoodsNomenclatureSelfText
  include ApiEntity
  include GeneratedContentResource

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
             :eu_self_text,
             :similarity_score,
             :coherence_score,
             :nomenclature_type,
             :score,
             :has_label

  def to_param
    goods_nomenclature_sid&.to_s || goods_nomenclature_id
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

private

  def generated_content_member_path
    "admin/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text"
  end

  def listing_description
    self_text
  end

  def listing_description_key
    :self_text
  end

  def score_value_for_tags
    combined_score
  end
end
