# The per-gold-query outcomes of one run. Nested under the run in this app's own routes for a readable
# URL, even though the backend's own route for results is flat (see EvaluationResult's own comment).
class EvaluationResultsController < AuthenticatedController
  include UkOnly

  rescue_from Faraday::Error, with: :redirect_result_unavailable
  rescue_from Faraday::ResourceNotFound, with: :redirect_result_not_found

  def index
    authorize EvaluationResult, :index?

    @results = fetch_results
  end

  def show
    authorize EvaluationResult, :show?

    @result = EvaluationResult.find(params[:id])
  end

private

  def fetch_results
    EvaluationResult.all(params.permit(:page).to_h.symbolize_keys.merge(run_id: params[:evaluation_run_id]))
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch results: #{e.message}")
    flash.now[:alert] = "Results could not be loaded. Try again."
    Kaminari.paginate_array([]).page(1)
  end

  # Unlike #index (a list with a sensible empty state), a single result's show page has nothing
  # useful to render without the result itself — same reasoning as EvaluationRunsController's own
  # show page, which redirects away on a genuine outage rather than rendering a blank detail page.
  def redirect_result_unavailable
    redirect_to evaluation_run_results_path(params[:evaluation_run_id]), alert: "Result could not be loaded. Try again."
  end

  def redirect_result_not_found
    redirect_to evaluation_run_results_path(params[:evaluation_run_id]), alert: "Result not found."
  end
end
