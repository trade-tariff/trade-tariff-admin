class AdminConfiguration
  include ApiEntity

  uk_only

  set_collection_path "admin/admin_configurations"

  attributes :name,
             :value,
             :config_type,
             :area,
             :description,
             :deleted

  # Version metadata from API response
  attr_accessor :version_current,
                :version_oid,
                :version_previous_oid,
                :version_has_previous

  def current?
    version_current != false
  end

  def has_previous_version?
    version_has_previous == true
  end

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

  def display_value
    case config_type
    when "boolean"
      value == true ? "Yes" : "No"
    when "integer"
      value.to_s
    when "options"
      selected_option_label
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
    body = handle_body(response)
    parsed = parse_jsonapi(response)

    config = new(parsed)

    if body.is_a?(Hash) && body["meta"]&.dig("version")
      version = body["meta"]["version"]
      config.version_current = version["current"]
      config.version_oid = version["oid"]
      config.version_previous_oid = version["previous_oid"]
      config.version_has_previous = version["has_previous_version"]
    end

    config
  end

  def self.handle_body(resp)
    body = resp.try(:body) || resp.try(:[], :body)

    return "" if body.blank?
    return JSON.parse(body) if body.is_a?(String)

    body
  end
  private_class_method :handle_body
end
