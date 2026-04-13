class AdminConfiguration
  include ApiEntity
  include VersionMetadata

  uk_only

  set_collection_path "admin/admin_configurations"

  attributes :name,
             :value,
             :config_type,
             :area,
             :description,
             :deleted

  def to_param
    resource_id
  end

  def display_name
    name&.titleize
  end

  def preview(field_name = :value)
    return unless config_type == "markdown"

    content = public_send(field_name)
    GovspeakPreview.new(content).render if content.present?
  end

  def selected_option_label
    return unless config_type == "options" && value.is_a?(Hash)

    selected = value["selected"]
    options = value["options"] || []
    option = options.find { |o| o["key"] == selected }
    option&.dig("label") || selected
  end

  def multi_selected_labels
    return [] unless config_type == "multi_options" && value.is_a?(Hash)

    selected_values = Array(value["selected"])
    options = value["options"] || []

    selected_values.filter_map do |selected|
      option = options.find { |o| o["key"] == selected }
      option&.dig("label") || selected
    end
  end

  def nested_selected_label
    return unless config_type == "nested_options" && value.is_a?(Hash)

    selected = value["selected"]
    options = value["options"] || []
    option = options.find { |o| o["key"] == selected }
    option&.dig("label") || selected
  end

  def nested_sub_value(key)
    return unless config_type == "nested_options" && value.is_a?(Hash)

    sub_values = value["sub_values"]
    return unless sub_values.is_a?(Hash)

    sub_values[key]
  end

  def display_value
    case config_type
    when "boolean"
      value == true ? "Yes" : "No"
    when "integer"
      value.to_s
    when "options"
      selected_option_label
    when "multi_options"
      multi_selected_labels.join(", ")
    when "nested_options"
      label = nested_selected_label
      sub_values = value.is_a?(Hash) ? value["sub_values"] : nil
      if sub_values.is_a?(Hash) && sub_values.values.any?(&:present?)
        sub_parts = sub_values.filter_map { |k, v| "#{k.tr('_', ' ')}: #{v}" if v.present? }
        "#{label} (#{sub_parts.join(', ')})"
      else
        label
      end
    when "markdown"
      preview
    else
      value
    end
  end

  # Override find to extract version metadata from API response
  def self.find(config_name, opts = {})
    entity = new(resource_id: config_name)
    path = entity.singular_path

    filter_opts = {}
    filter_opts[:filter] = { oid: opts[:oid] } if opts[:oid].present?

    response = api.get(path, filter_opts)
    parsed = parse_jsonapi(response)

    config = new(parsed)
    config.extract_version_meta!(response)

    config
  end
end
