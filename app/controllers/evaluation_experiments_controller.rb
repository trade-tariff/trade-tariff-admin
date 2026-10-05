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
  end

  def create
    authorize EvaluationExperiment, :create?

    @experiment = EvaluationExperiment.new(experiment_params)

    if @experiment.save && @experiment.errors.empty?
      redirect_to evaluation_experiments_path, notice: "Experiment created successfully."
    else
      @gold_query_sets = fetch_gold_query_sets
      render :new, status: :unprocessable_content
    end
  end

  def confirm_destroy
    authorize @experiment, :destroy?

    @run_count = EvaluationRun.all(experiment_id: @experiment.resource_id, per_page: 1).total_count
  end

  def destroy
    authorize @experiment, :destroy?

    @experiment.destroy
    redirect_to evaluation_experiments_path, notice: "Experiment deleted successfully."
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

  def experiment_params
    params.require(:evaluation_experiment).permit(:name, :description, :gold_query_set_id)
  end
end
