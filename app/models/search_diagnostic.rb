class SearchDiagnostic
  include ApiEntity

  attributes :request_id, :log_group_name, :start_time, :end_time, :events

  set_singular_path "admin/search_diagnostics/:request_id"

  def to_param
    request_id.presence || resource_id
  end

  def events
    Array(attributes[:events]).map(&:with_indifferent_access)
  end

  def events?
    events.any?
  end
end
