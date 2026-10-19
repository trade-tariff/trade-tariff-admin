class EvaluationExperimentsController < AuthenticatedController
  include UkOnly

  rescue_from Faraday::Error, with: :redirect_experiment_unavailable
  rescue_from Faraday::ResourceNotFound, with: :redirect_experiment_not_found

  before_action :load_experiment, only: %i[confirm_destroy destroy]

  def index
    authorize EvaluationExperiment, :index?

    @experiments = fetch_experiments
  end

  def new
    authorize EvaluationExperiment, :create?

    @experiment = EvaluationExperiment.new
    @gold_query_sets = fetch_gold_query_sets
    @synthetic_input_sets = fetch_synthetic_input_sets
  end

  def create
    authorize EvaluationExperiment, :create?

    @experiment = EvaluationExperiment.new(experiment_params)

    if @experiment.save && @experiment.errors.empty?
      redirect_to evaluation_experiments_path, notice: "Experiment created successfully."
    else
      # source_type is form-only (never sent to or read from the backend), so unlike the other
      # fields it is not already on @experiment from experiment_params -- read it back from the
      # submitted params directly, purely so the chosen radio stays chosen on this re-render.
      @experiment.source_type = params.dig(:evaluation_experiment, :source_type)
      @gold_query_sets = fetch_gold_query_sets
      @synthetic_input_sets = fetch_synthetic_input_sets
      render :new, status: :unprocessable_content
    end
  end

  def confirm_destroy
    authorize @experiment, :destroy?

    @run_count = EvaluationRun.all(experiment_id: @experiment.resource_id, per_page: 1).total_count
  end

  def destroy
    authorize @experiment, :destroy?

    @experiment.destroy!
    redirect_to evaluation_experiments_path, notice: "Experiment deleted successfully."
  rescue Faraday::ConflictError => e
    redirect_to evaluation_experiments_path, alert: EvaluationExperiment.conflict_detail(e)
  end

private

  def load_experiment
    @experiment = EvaluationExperiment.find(params[:id])
  end

  def redirect_experiment_not_found
    redirect_to evaluation_experiments_path, alert: "Experiment not found."
  end

  def redirect_experiment_unavailable
    redirect_to evaluation_experiments_path, alert: "The experiment could not be loaded. Try again."
  end

  def fetch_experiments
    EvaluationExperiment.all(params.permit(:page).to_h.symbolize_keys)
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch experiments: #{e.message}")
    flash.now[:alert] = "Experiments could not be loaded. Try again."
    Kaminari.paginate_array([]).page(1)
  end

  def fetch_gold_query_sets
    EvaluationGoldQuerySet.all(per_page: 200)
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch gold query sets: #{e.message}")
    Kaminari.paginate_array([]).page(1)
  end

  def fetch_synthetic_input_sets
    EvaluationSyntheticInputSet.all(per_page: 200)
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch synthetic input sets: #{e.message}")
    Kaminari.paginate_array([]).page(1)
  end

  # The conditional reveal only hides the inactive picker with CSS -- its <select> keeps
  # whatever it last held, so switching radios without reloading the page can submit both ids
  # at once. source_type says which pick is the operator's actual final choice, so the other
  # id is dropped here rather than forwarded to a backend that would otherwise reject the
  # request as "cannot be set at the same time" even though the operator only picked one.
  def experiment_params
    permitted = params.require(:evaluation_experiment).permit(:name, :description, :source_type, :gold_query_set_id, :synthetic_input_set_id)
    source_type = permitted.delete(:source_type)

    case source_type
    when "gold_query_set" then permitted[:synthetic_input_set_id] = nil
    when "synthetic_input_set" then permitted[:gold_query_set_id] = nil
    end

    permitted
  end
end
