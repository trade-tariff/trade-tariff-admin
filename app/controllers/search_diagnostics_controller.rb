class SearchDiagnosticsController < AuthenticatedController
  def index
    authorize SearchDiagnostic, :index?

    if request_id.present?
      redirect_to search_diagnostic_path(request_id, preserved_filters)
      return
    end

    return if browser_session_id.blank? && experiment.blank?
    return redirect_to search_diagnostics_path, alert: "Enter a valid browser session or experiment." unless valid_correlation_filter?

    @related_diagnostics = SearchDiagnostic.collection(correlation_params)
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch related search diagnostics: #{e.class} #{e.message}")
    redirect_to search_diagnostics_path, alert: "Related search requests could not be loaded."
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
    }.merge(preserved_filters).compact_blank
  end
end
