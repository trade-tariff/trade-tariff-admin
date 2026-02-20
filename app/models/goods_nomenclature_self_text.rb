class GoodsNomenclatureSelfText
  include ApiEntity

  uk_only

  set_singular_path "admin/goods_nomenclatures/:goods_nomenclature_id/goods_nomenclature_self_text"
  set_collection_path "admin/goods_nomenclature_self_texts"

  attributes :goods_nomenclature_sid,
             :goods_nomenclature_item_id,
             :self_text,
             :generation_type,
             :input_context,
             :needs_review,
             :manually_edited,
             :stale,
             :generated_at,
             :eu_self_text,
             :similarity_score,
             :coherence_score,
             :nomenclature_type,
             :score

  attr_accessor :goods_nomenclature_id

  def self.find(goods_nomenclature_id, opts = {})
    entity = new({ goods_nomenclature_id: goods_nomenclature_id }.merge(opts))
    path = entity.singular_path

    response = api.get(path, opts.except(*entity.cleaned_path_attributes))
    parsed = parse_jsonapi(response)

    record = new(parsed)
    record.goods_nomenclature_id = goods_nomenclature_id
    record
  end

  def to_param
    goods_nomenclature_id || goods_nomenclature_item_id
  end

  def generate_score
    api.post("admin/goods_nomenclatures/#{goods_nomenclature_id}/goods_nomenclature_self_text/score")
  end

  def regenerate
    api.post("admin/goods_nomenclatures/#{goods_nomenclature_id}/goods_nomenclature_self_text/regenerate")
  end

  def approve
    api.post("admin/goods_nomenclatures/#{goods_nomenclature_id}/goods_nomenclature_self_text/approve")
  end

  def reject
    api.post("admin/goods_nomenclatures/#{goods_nomenclature_id}/goods_nomenclature_self_text/reject")
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
    return "Amazing" if value >= 0.85
    return "Good" if value >= 0.5
    return "Okay" if value >= 0.3

    "Bad"
  end

  def score_tag_colour(value = combined_score)
    return "grey" if value.nil?
    return "blue" if value >= 0.85
    return "green" if value >= 0.5
    return "yellow" if value >= 0.3

    "red"
  end

  def formatted_generated_at
    return "-" if generated_at.blank?

    date = Date.parse(generated_at.to_s)
    date == Date.current ? "Today" : date.to_formatted_s(:govuk)
  rescue ArgumentError
    generated_at.to_s
  end

  def ancestor_chain
    return [] unless input_context.is_a?(Hash)

    (input_context["ancestors"] || []).map { |a| a["self_text"] || a["description"] }
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
