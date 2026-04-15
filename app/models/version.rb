class Version
  include ApiEntity

  attributes :id, :item_type, :item_id, :event, :object, :whodunnit, :created_at, :changeset, :previous_version_id

  FRIENDLY_TYPE_NAMES = {
    "GoodsNomenclatureLabel" => "Label",
    "GoodsNomenclatureSelfText" => "Self-text",
    "SearchReference" => "Search reference",
    "AdminConfiguration" => "Configuration",
    "DescriptionIntercept" => "Description intercept",
  }.freeze

  def whodunnit_name
    return nil if whodunnit.blank?

    User.find_by(uid: whodunnit)&.name || whodunnit
  end

  def created_at_formatted
    return "-" if created_at.blank?

    time = Time.zone.parse(created_at.to_s)
    time.to_date == Date.current ? "Today #{time.strftime('%H:%M')}" : time.strftime("%d %b %Y %H:%M")
  rescue ArgumentError
    created_at.to_s
  end

  def friendly_type_name
    FRIENDLY_TYPE_NAMES[item_type] || item_type
  end

  def item_description
    return nil unless object.is_a?(Hash)

    object["goods_nomenclature_item_id"] || object["term"] || object["name"] || object["title"] || item_id
  end

  def changed_fields
    changeset&.dig("changed_fields") || []
  end

  def changes
    changeset&.dig("changes") || {}
  end

  def has_changeset?
    changeset.present? && changed_fields.any?
  end
end
