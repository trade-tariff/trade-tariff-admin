class EvaluationGoldQuerySetsController < AuthenticatedController
  rescue_from Faraday::ResourceNotFound, with: :redirect_gold_query_set_not_found

  before_action :load_gold_query_set, only: %i[show confirm_destroy destroy]

  def index
    authorize EvaluationGoldQuerySet, :index?

    @gold_query_sets = fetch_gold_query_sets
  end

  def new
    authorize EvaluationGoldQuerySet, :create?

    # Real ATaR rulings only is what the command-line task did before sets existed.
    @gold_query_set = EvaluationGoldQuerySet.new(atar_percentage: 100)
  end

  def create
    authorize EvaluationGoldQuerySet, :create?

    @gold_query_set = EvaluationGoldQuerySet.new(gold_query_set_params)

    if @gold_query_set.save && @gold_query_set.errors.empty?
      redirect_to evaluation_gold_query_set_path(@gold_query_set), notice: "Gold query set created. It is being generated in the background."
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    authorize EvaluationGoldQuerySet, :show?

    @items = fetch_items
  end

  def confirm_destroy
    authorize @gold_query_set, :destroy?
  end

  def destroy
    authorize @gold_query_set, :destroy?

    @gold_query_set.destroy
    redirect_to evaluation_gold_query_sets_path, notice: "Gold query set deleted successfully."
  rescue Faraday::ConflictError => e
    redirect_to evaluation_gold_query_set_path(@gold_query_set),
                alert: EvaluationGoldQuerySet.conflict_detail(e) || "The gold query set could not be deleted because it is in use."
  end

private

  def load_gold_query_set
    @gold_query_set = EvaluationGoldQuerySet.find(params[:id])
  end

  def redirect_gold_query_set_not_found
    redirect_to evaluation_gold_query_sets_path, alert: "Gold query set not found."
  end

  def fetch_gold_query_sets
    EvaluationGoldQuerySet.all(params.permit(:page).to_h.symbolize_keys)
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch gold query sets: #{e.message}")
    flash.now[:alert] = "Gold query sets could not be loaded. Try again."
    Kaminari.paginate_array([]).page(1)
  end

  # Nil when the items cannot be loaded, so the page can still show the set itself.
  def fetch_items
    EvaluationGoldQueryItem.all(params.permit(:page).to_h.symbolize_keys.merge(gold_query_set_id: @gold_query_set.resource_id))
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch gold query set items: #{e.message}")
    flash.now[:alert] = "The items of this set could not be loaded. Try again."
    nil
  end

  def gold_query_set_params
    params.require(:evaluation_gold_query_set).permit(:name, :requested_size, :atar_percentage)
  end
end
