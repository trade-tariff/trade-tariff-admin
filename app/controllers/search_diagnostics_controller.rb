class SearchDiagnosticsController < AuthenticatedController
  def index
    authorize SearchDiagnostic, :index?

    redirect_to search_diagnostic_path(request_id) if request_id.present?
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
    params.permit(:lookback_hours, :limit).to_h.compact_blank
  end
end
