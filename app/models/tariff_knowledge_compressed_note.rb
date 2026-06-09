class TariffKnowledgeCompressedNote
  include ApiEntity
  include GeneratedContentResource

  set_collection_path "admin/tariff_knowledge_compressed_notes"
  set_singular_path "admin/goods_nomenclatures/:goods_nomenclature_id/tariff_knowledge_compressed_note"

  attributes :goods_nomenclature_sid,
             :goods_nomenclature_item_id,
             :producline_suffix,
             :goods_nomenclature_type,
             :content,
             :metadata,
             :context_hash,
             :needs_review,
             :manually_edited,
             :stale,
             :approved,
             :expired,
             :generated_at,
             :created_at,
             :updated_at

  def to_param
    goods_nomenclature_sid&.to_s || goods_nomenclature_id
  end

  def source_node_keys
    metadata_array("source_node_keys")
  end

  def range_node_keys
    metadata_array("range_node_keys")
  end

private

  def generated_content_member_path
    "admin/goods_nomenclatures/#{to_param}/tariff_knowledge_compressed_note"
  end

  def listing_description
    content
  end

  def listing_description_key
    :content
  end

  def listing_score
    nil
  end

  def metadata_array(key)
    return [] unless metadata.is_a?(Hash)

    Array(metadata[key]).compact
  end
end
