class TariffKnowledgeSyntheticAtar
  include ApiEntity
  include RecordDateFormatting

  uk_only

  attributes :chapter,
             :real_user_search,
             :times_searched,
             :likely_heading,
             :description,
             :goods_nomenclature_item_id,
             :notes,
             :completed_by,
             :created_at,
             :updated_at

  def description_summary
    description.to_s.truncate(90)
  end

  def times_searched_label
    times_searched.presence || "-"
  end
end
