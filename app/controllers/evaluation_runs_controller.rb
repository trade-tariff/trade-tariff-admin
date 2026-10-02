class EvaluationRunsController < AuthenticatedController
  include UkOnly

  # Registered before the more specific ResourceNotFound handler, so a run that genuinely doesn't
  # exist still gets its own message — Rails checks rescue_from handlers in reverse-registration
  # order, so the more specific one, added second, is checked first. Same ordering already used by
  # EvaluationGoldQuerySetsController.
  rescue_from Faraday::Error, with: :redirect_run_unavailable
  rescue_from Faraday::ResourceNotFound, with: :redirect_run_not_found

  def new
    authorize EvaluationRun, :create?

    @run = EvaluationRun.new
    @idempotency_key = SecureRandom.uuid
    @experiments = fetch_experiments
    @gold_query_sets = fetch_gold_query_sets
    @configuration_schema = EvaluationConfiguration.schema
  end

  def create
    authorize EvaluationRun, :create?

    @configuration_schema = EvaluationConfiguration.schema
    @run = EvaluationRun.launch!(
      experiment_id: run_params[:experiment_id],
      triggered_by: Current.whodunnit,
      run_time_overrides: override_params,
      idempotency_key: run_params[:idempotency_key],
    )

    if @run.errors.empty?
      redirect_to evaluation_run_path(@run)
    else
      @idempotency_key = run_params[:idempotency_key]
      @experiments = fetch_experiments
      @gold_query_sets = fetch_gold_query_sets
      render :new, status: :unprocessable_content
    end
  end

private

  def fetch_experiments
    EvaluationExperiment.all(per_page: 200)
  end

  def fetch_gold_query_sets
    EvaluationGoldQuerySet.all(per_page: 200)
  end

  def run_params
    params.require(:evaluation_run).permit(:experiment_id, :idempotency_key)
  end

  # gold_query_set_id travels as a configuration override (not a top-level run attribute) because
  # the backend resolves the run's set from its experiment by default, and a run-time override is
  # exactly how this form lets the operator pick a different one for just this launch — same
  # mechanism as every other override, not a special case.
  def override_params
    allowed_keys = @configuration_schema[:allowed_overrides].map { |entry| entry[:name] } + %w[gold_query_set_id]

    params.require(:evaluation_run).to_unsafe_h.slice(*allowed_keys.map(&:to_s)).reject { |_, value| value.blank? }
  end

  # The launch form needs all three of @experiments, @gold_query_sets and @configuration_schema to
  # render meaningfully — unlike a list page, there's no useful partial state to show if one of
  # them fails, so any Faraday::Error from any of them is left to propagate to the class-level
  # rescue_from above rather than being caught per-fetch here.
  def redirect_run_unavailable
    redirect_to evaluation_experiments_path, alert: "The launch form could not be loaded. Try again."
  end

  def redirect_run_not_found
    redirect_to evaluation_experiments_path, alert: "Run not found."
  end
end
