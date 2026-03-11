module VersionsHelper
  def version_item_link(version)
    oid = version_oid(version)
    opts = oid ? { oid: oid } : {}

    case version.item_type
    when "GoodsNomenclatureLabel"
      item_id = version.object&.dig("goods_nomenclature_item_id")
      goods_nomenclature_label_path(item_id, **opts) if item_id.present?
    when "GoodsNomenclatureSelfText"
      goods_nomenclature_self_text_path(version.item_id, **opts) if version.item_id.present?
    when "AdminConfiguration"
      name = version.object&.dig("name")
      classification_configuration_path(name, **opts) if name.present?
    end
  end

  def changeset_summary(version)
    return "Initial version" if version.event == "create"
    return nil unless version.has_changeset?

    fields = version.changed_fields.map { |f| f.humanize(capitalize: true) }
    "Changed: #{fields.join(', ')}"
  end

  def changeset_detail_html(version)
    return nil unless version.has_changeset?

    safe_join(version.changes.map { |field, change| render_field_change(field, change) })
  end

private

  def version_oid(version)
    version.resource_id
  end

  def render_field_change(field, change)
    content_tag(:div, class: "diff-field") do
      content_tag(:strong, field.humanize(capitalize: true), class: "diff-field__label") +
        render_change(change)
    end
  end

  def render_change(change)
    case change["type"]
    when "text"   then render_text_change(change)
    when "array"  then render_array_change(change)
    when "simple" then render_simple_change(change)
    end
  end

  def render_text_change(change)
    content_tag(:div, class: "diff-field__content") do
      safe_join(change["diff"].map { |op| text_op_tag(op) })
    end
  end

  def text_op_tag(operation)
    case operation["op"]
    when "equal"  then content_tag(:span, operation["text"], class: "diff-unchanged")
    when "insert" then content_tag(:ins, operation["text"], class: "diff-insert")
    when "delete" then content_tag(:del, operation["text"], class: "diff-delete")
    end
  end

  def render_array_change(change)
    content_tag(:div, class: "diff-field__content diff-array") do
      pills = []
      pills += change["removed"].map { |v| content_tag(:span, v, class: "diff-pill diff-pill--removed") }
      pills += change["added"].map { |v| content_tag(:span, v, class: "diff-pill diff-pill--added") }
      pills += change["unchanged"].map { |v| content_tag(:span, v, class: "diff-pill diff-pill--unchanged") }
      safe_join(pills)
    end
  end

  def render_simple_change(change)
    content_tag(:div, class: "diff-field__content") do
      content_tag(:del, change["old"].to_s, class: "diff-delete") +
        content_tag(:span, " -> ", class: "diff-unchanged") +
        content_tag(:ins, change["new"].to_s, class: "diff-insert")
    end
  end
end
