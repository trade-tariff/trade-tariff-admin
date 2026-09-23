class SearchDiagnostic
  include ApiEntity

  BROWSER_SESSION_ID_FORMAT = /\Av1:[0-9a-f]{64}\z/
  EXPERIMENT_FORMAT = /\A[A-Za-z0-9][A-Za-z0-9_-]{0,63}\z/

  attributes :request_id,
             :log_group_name,
             :start_time,
             :end_time,
             :events,
             :experiment,
             :browser_session_id,
             :related_requests,
             :related_requests_available,
             :occurred_at,
             :query

  set_singular_path "admin/search_diagnostics/:request_id"
  set_collection_path "admin/search_diagnostics"

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
