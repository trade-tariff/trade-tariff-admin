# The source items of one gold query set. An item is an ATaR ruling or a synthetic ATaR
# with the three test searches written for it. There is no page for a single item, because
# the set page lists them. An item is edited or deleted from there.
class EvaluationGoldQueryItemsController < AuthenticatedController
  rescue_from Faraday::ResourceNotFound, with: :redirect_item_not_found

  before_action :load_gold_query_set, only: %i[edit update confirm_destroy]
  before_action :load_item, only: %i[edit update confirm_destroy destroy]

  def edit
    authorize @item, :update?

    @versions = fetch_versions
  end

  def update
    authorize @item, :update?

    @item.assign_attributes(item_params)

    if @item.save && @item.errors.empty?
      redirect_to evaluation_gold_query_set_path(@gold_query_set), notice: "Test searches updated successfully."
    else
      @versions = fetch_versions
      render :edit, status: :unprocessable_content
    end
  end

  def confirm_destroy
    authorize @item, :destroy?
  end

  def destroy
    authorize @item, :destroy?

    @item.destroy
    redirect_to evaluation_gold_query_set_path(params[:evaluation_gold_query_set_id]), notice: "Item deleted successfully."
  end

private

  def load_gold_query_set
    @gold_query_set = EvaluationGoldQuerySet.find(params[:evaluation_gold_query_set_id])
  end

  def load_item
    @item = EvaluationGoldQueryItem.find_in_set(params[:evaluation_gold_query_set_id], params[:id])
  end

  # A set that does not exist is reported by the set page, which this redirect lands on.
  def redirect_item_not_found
    redirect_to evaluation_gold_query_set_path(params[:evaluation_gold_query_set_id]), alert: "Gold query set item not found."
  end

  def fetch_versions
    @item.versions
  rescue StandardError => e
    Rails.logger.error("Failed to fetch versions: #{e.message}")
    []
  end

  def item_params
    params.require(:evaluation_gold_query_item).permit(
      :expected_code,
      *EvaluationGoldQueryItem::PERSONAS.keys.flat_map { |persona| [:"#{persona}_query", :"#{persona}_notes"] },
    )
  end
end
