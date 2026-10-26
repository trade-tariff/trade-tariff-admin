class EvaluationSyntheticInputSetsController < AuthenticatedController
  include UkOnly

  rescue_from Faraday::Error, with: :redirect_synthetic_input_set_unavailable
  rescue_from Faraday::ResourceNotFound, with: :redirect_synthetic_input_set_not_found

  before_action :load_synthetic_input_set, only: %i[show confirm_destroy destroy]

  def index
    authorize EvaluationSyntheticInputSet, :index?

    @synthetic_input_sets = fetch_synthetic_input_sets
  end

  def new
    authorize EvaluationSyntheticInputSet, :create?

    @synthetic_input_set = EvaluationSyntheticInputSet.new
  end

  def create
    authorize EvaluationSyntheticInputSet, :create?

    @synthetic_input_set = EvaluationSyntheticInputSet.new(synthetic_input_set_params)

    if @synthetic_input_set.save && @synthetic_input_set.errors.empty?
      redirect_to evaluation_synthetic_input_set_path(@synthetic_input_set), notice: "Synthetic input set created."
    else
      render :new, status: :unprocessable_content
    end
  rescue Faraday::Error
    redirect_to new_evaluation_synthetic_input_set_path, alert: "The synthetic input set could not be created. Try again."
  end

  def show
    authorize EvaluationSyntheticInputSet, :show?

    @items = fetch_items
  end

  def confirm_destroy
    authorize @synthetic_input_set, :destroy?
  end

  def destroy
    authorize @synthetic_input_set, :destroy?

    @synthetic_input_set.destroy!
    redirect_to evaluation_synthetic_input_sets_path, notice: "Synthetic input set deleted successfully."
  rescue Faraday::ConflictError => e
    redirect_to evaluation_synthetic_input_set_path(@synthetic_input_set),
                alert: EvaluationSyntheticInputSet.conflict_detail(e) || "The synthetic input set could not be deleted because it is in use."
  rescue Faraday::Error
    redirect_to evaluation_synthetic_input_set_path(@synthetic_input_set), alert: "The synthetic input set could not be deleted. Try again."
  end

private

  def load_synthetic_input_set
    @synthetic_input_set = EvaluationSyntheticInputSet.find(params[:id])
  end

  def redirect_synthetic_input_set_not_found
    redirect_to evaluation_synthetic_input_sets_path, alert: "Synthetic input set not found."
  end

  def redirect_synthetic_input_set_unavailable
    redirect_to evaluation_synthetic_input_sets_path, alert: "The synthetic input set could not be loaded. Try again."
  end

  # Nil when the sets cannot be loaded, so the page does not claim there are none. This page
  # is where an operator checks existing names before creating a set.
  def fetch_synthetic_input_sets
    EvaluationSyntheticInputSet.all(params.permit(:page).to_h.symbolize_keys)
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch synthetic input sets: #{e.message}")
    flash.now[:alert] = "Synthetic input sets could not be loaded. Try again."
    nil
  end

  # Nil when the items cannot be loaded, so the page can still show the set itself.
  def fetch_items
    EvaluationSyntheticInputSetItem.all(params.permit(:page).to_h.symbolize_keys.merge(synthetic_input_set_id: @synthetic_input_set.resource_id))
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch synthetic input set items: #{e.message}")
    flash.now[:alert] = "The items of this set could not be loaded. Try again."
    nil
  end

  def synthetic_input_set_params
    params.require(:evaluation_synthetic_input_set).permit(:name, :requested_size)
  end
end
