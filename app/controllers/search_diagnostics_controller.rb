class SearchDiagnosticsController < AuthenticatedController
  def index
    authorize SearchDiagnostic, :index?

    if search_reference.present?
      target = target_for(search_reference)
      return redirect_to(search_diagnostics_path(preserved_filters), alert: invalid_reference_alert) if target.blank?

      redirect_to target
      return
    end

    return if browser_session_id.blank? && experiment.blank?
    return redirect_to search_diagnostics_path(preserved_filters), alert: invalid_reference_alert unless valid_correlation_filter?

    @list_window = explicit_lookback_hours ? "the last #{explicit_lookback_hours} hours" : "today"
    @applied_lookback_hours = applied_lookback_hours
    @related_diagnostics = current_day_requests(SearchDiagnostic.collection(correlation_params))
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch related search diagnostics: #{e.class} #{e.message}")
    redirect_to search_diagnostics_path(preserved_filters), alert: "Related search requests could not be loaded."
  end

  def show
    authorize SearchDiagnostic, :show?

    @request_id = request_id
    @search_diagnostic = SearchDiagnostic.find(@request_id, search_params)
  rescue Faraday::ResourceNotFound
    redirect_to search_diagnostics_path, alert: "Search diagnostics were not found for that request ID."
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch search diagnostics for #{request_id}: #{e.class} #{e.message}")
    redirect_to search_diagnostics_path, alert: "Search diagnostics could not be loaded."
  end

private

  def request_id
    params[:request_id].to_s.strip
  end

  def search_reference
    params[:search_reference].to_s.strip.presence || params[:request_id].to_s.strip.presence
  end

  def target_for(reference)
    case reference
    when SearchDiagnostic::REQUEST_ID_FORMAT
      search_diagnostic_path(reference, preserved_filters)
    when SearchDiagnostic::BROWSER_SESSION_ID_FORMAT
      search_diagnostics_path({ browser_session_id: reference }.merge(preserved_filters))
    when SearchDiagnostic::EXPERIMENT_FORMAT
      search_diagnostics_path({ experiment: reference }.merge(preserved_filters))
    end
  end

  def invalid_reference_alert
    "Enter a valid request ID, browser session, or experiment."
  end

  def search_params
    preserved_filters
  end

  def preserved_filters
    params.permit(:lookback_hours, :limit).to_h.compact_blank
  end

  def browser_session_id
    params[:browser_session_id].to_s.strip
  end

  def experiment
    params[:experiment].to_s.strip
  end

  def valid_correlation_filter?
    return false if browser_session_id.present? && experiment.present?
    return browser_session_id.match?(SearchDiagnostic::BROWSER_SESSION_ID_FORMAT) if browser_session_id.present?

    experiment.match?(SearchDiagnostic::EXPERIMENT_FORMAT)
  end

  def correlation_params
    {
      browser_session_id: browser_session_id.presence,
      experiment: experiment.presence,
      lookback_hours: applied_lookback_hours,
    }.merge(preserved_filters.except("lookback_hours", :lookback_hours)).compact_blank
  end

  def applied_lookback_hours
    explicit_lookback_hours || current_day_lookback_hours
  end

  def explicit_lookback_hours
    return if params[:lookback_hours].blank?

    Integer(params[:lookback_hours]).clamp(SearchDiagnostic::MIN_LOOKBACK_HOURS, SearchDiagnostic::MAX_LOOKBACK_HOURS)
  rescue ArgumentError, TypeError
    nil
  end

  def current_day_lookback_hours
    elapsed_hours = ((Time.zone.now - current_day_start) / 1.hour).ceil

    elapsed_hours.clamp(SearchDiagnostic::MIN_LOOKBACK_HOURS, SearchDiagnostic::MAX_LOOKBACK_HOURS)
  end

  def current_day_start
    ActiveSupport::TimeZone[SearchDiagnostic::OPERATOR_TIME_ZONE].now.beginning_of_day
  end

  def current_day_requests(diagnostics)
    return diagnostics if explicit_lookback_hours

    diagnostics.select { |diagnostic| current_day_request?(diagnostic.occurred_at) }
  end

  def current_day_request?(occurred_at)
    parsed = Time.zone.parse(occurred_at.to_s)
    return true if parsed.blank?

    parsed >= current_day_start
  rescue ArgumentError
    true
  end
end
