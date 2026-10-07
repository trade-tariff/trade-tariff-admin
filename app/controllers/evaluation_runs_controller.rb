class EvaluationRunsController < AuthenticatedController
  include UkOnly

  # Registered before the more specific ResourceNotFound handler, so a run that genuinely doesn't
  # exist still gets its own message — Rails checks rescue_from handlers in reverse-registration
  # order, so the more specific one, added second, is checked first. Same ordering already used by
  # EvaluationGoldQuerySetsController.
  rescue_from Faraday::Error, with: :redirect_run_unavailable
  rescue_from Faraday::ResourceNotFound, with: :redirect_run_not_found

  before_action :load_run, only: %i[show cancel]

  def index
    authorize EvaluationRun, :index?

    @runs = fetch_runs
  end

  def new
    authorize EvaluationRun, :create?

    @run = EvaluationRun.new
    @idempotency_key = SecureRandom.uuid
    @experiments = fetch_experiments
    @gold_query_sets_by_id = fetch_gold_query_sets.index_by { |set| set.resource_id.to_s }
    @configuration_schema = EvaluationConfiguration.schema
  end

  def create
    authorize EvaluationRun, :create?

    @configuration_schema = EvaluationConfiguration.schema
    @run = if run_params[:experiment_id].blank?
             # Caught here, not left to the backend: the select has a blank "Choose an experiment"
             # option and nothing stops submitting it as-is. Without this, EvaluationExperiment.with_pk!
             # on the backend rejects an empty id with a 404 (or worse, a 500 from Postgres casting an
             # empty string to an integer id), which this controller's own Faraday::Error rescue below
             # would then report as "the evaluation service could not be reached" — true of nothing, and
             # retrying it changes nothing.
             EvaluationRun.new.tap { |run| run.errors.add(:experiment_id, "Choose an experiment") }
           else
             begin
               EvaluationRun.launch!(
                 experiment_id: run_params[:experiment_id],
                 triggered_by: Current.whodunnit,
                 run_time_overrides: override_params,
                 idempotency_key: run_params[:idempotency_key],
               )
             rescue Faraday::ConflictError
               # This Idempotency-Key was already used for a request with different inputs (backend's
               # own IdempotencyKeyConflict, raised as a 409) — the realistic way to hit this is a
               # timeout: the backend created a run, the response never arrived here, the form re-rendered
               # with the same key, and the operator then changed something before resubmitting. The run
               # from the first attempt already exists; "could not be reached" would send them around that
               # loop again instead of telling them what's actually going on.
               EvaluationRun.new.tap { |run| run.errors.add(:base, "A run was already started from this form. Reload the page to start a new one.") }
             rescue Faraday::Error => e
               Rails.logger.error("Failed to launch evaluation run: #{e.message}")
               EvaluationRun.new.tap { |run| run.errors.add(:base, "The evaluation service could not be reached. Try again.") }
             end
           end

    if @run.errors.empty?
      redirect_to evaluation_run_path(@run)
    else
      @idempotency_key = run_params[:idempotency_key]
      @run.attributes.merge!(raw_override_params.merge("experiment_id" => run_params[:experiment_id]))
      @experiments = fetch_experiments
      @gold_query_sets_by_id = fetch_gold_query_sets.index_by { |set| set.resource_id.to_s }
      render :new, status: :unprocessable_content
    end
  end

  def show
    authorize @run, :show?

    @gold_query_set = fetch_gold_query_set
    respond_to do |format|
      # The page's own title (show.html.erb) needs the experiment name every time, generating or
      # not. The JSON poll only needs it once the run stops generating: that's when the status
      # partial it re-renders starts including the Configuration section, which also reads
      # @experiment — fetching it on every 2-second poll before then would be a wasted backend
      # call for a section that isn't shown yet.
      format.html { @experiment = fetch_experiment }
      format.json do
        @experiment = fetch_experiment unless @run.generating?
        render json: { pending: @run.generating?, html: render_to_string(partial: "status", formats: [:html]) }
      end
    end
  end

  def cancel
    authorize @run, :show?

    @run.cancel! if @run.cancellable?
    redirect_to evaluation_run_path(@run)
  end

private

  def load_run
    @run = EvaluationRun.find(params[:id])
  end

  def fetch_experiments
    EvaluationExperiment.all(per_page: 200)
  end

  def fetch_gold_query_sets
    EvaluationGoldQuerySet.all(per_page: 200)
  end

  # This local rescue, not the controller-wide rescue_from Faraday::Error above, is deliberate —
  # the run list degrades to "empty list plus a warning" the same way the experiment list and
  # gold-query-set list already do, rather than bouncing away entirely the way the launch form
  # does. A list page has a sensible empty state; the launch form and the single-run show page
  # don't.
  def fetch_runs
    EvaluationRun.all(params.permit(:page, :status, :experiment_id, :from, :to).to_h.symbolize_keys)
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch runs: #{e.message}")
    flash.now[:alert] = "Runs could not be loaded. Try again."
    Kaminari.paginate_array([]).page(1)
  end

  def run_params
    params.require(:evaluation_run).permit(:experiment_id, :idempotency_key)
  end

  def override_params
    schema_by_name = @configuration_schema[:allowed_overrides].index_by { |entry| entry[:name] }

    raw_override_params.each_with_object({}) do |(key, value), casted|
      casted[key] = cast_override_value(value, schema_by_name[key][:config_type])
    end
  end

  def raw_override_params
    allowed_keys = @configuration_schema[:allowed_overrides].map { |entry| entry[:name] }

    params.require(:evaluation_run).to_unsafe_h.slice(*allowed_keys.map(&:to_s)).reject { |_, value| value.blank? }
  end

  # A hand-crafted request (or a browser with JS disabled bypassing the number input's own
  # validation) could send a non-numeric string for an integer key — falling back to the raw
  # string here lets the backend's own AllowlistValidator reject it with its normal "must be an
  # Integer" error, the same clean validation failure an operator already sees for any other
  # rejected override, rather than this app raising a 500 on a malformed cast.
  def cast_override_value(value, config_type)
    case config_type
    when "integer" then Integer(value)
    when "boolean" then value == "true"
    else value
    end
  rescue ArgumentError
    value
  end

  def fetch_gold_query_set
    return nil if @run.gold_query_set_id.blank?

    EvaluationGoldQuerySet.find(@run.gold_query_set_id)
  rescue Faraday::Error
    nil
  end

  # No equivalent rescue to fetch_gold_query_set's: an experiment is never deleted while any of
  # its runs still exist (the backend cascades an experiment's own deletion to its runs), so a
  # run that loaded at all is guaranteed to have one. A Faraday::Error here is a genuine outage,
  # left to the class-level rescue_from like every other unhandled fetch in this controller.
  def fetch_experiment
    EvaluationExperiment.find(@run.experiment_id)
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
