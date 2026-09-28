class TariffKnowledgeSyntheticAtarsController < AuthenticatedController
  rescue_from Faraday::ResourceNotFound, with: :redirect_synthetic_atar_not_found

  before_action :load_synthetic_atar, only: %i[show edit update confirm_destroy destroy]

  def index
    authorize TariffKnowledgeSyntheticAtar, :index?

    @synthetic_atars = fetch_synthetic_atars
  end

  def new
    authorize TariffKnowledgeSyntheticAtar, :create?

    @synthetic_atar = TariffKnowledgeSyntheticAtar.new
  end

  def create
    authorize TariffKnowledgeSyntheticAtar, :create?

    @synthetic_atar = TariffKnowledgeSyntheticAtar.new(synthetic_atar_params)

    if @synthetic_atar.save && @synthetic_atar.errors.empty?
      redirect_to tariff_knowledge_synthetic_atar_path(@synthetic_atar), notice: "Synthetic ATaR created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    authorize TariffKnowledgeSyntheticAtar, :show?

    @versions = fetch_versions
  end

  def edit
    authorize TariffKnowledgeSyntheticAtar, :update?
  end

  def update
    authorize TariffKnowledgeSyntheticAtar, :update?

    @synthetic_atar.assign_attributes(synthetic_atar_params)

    if @synthetic_atar.save && @synthetic_atar.errors.empty?
      redirect_to tariff_knowledge_synthetic_atar_path(@synthetic_atar), notice: "Synthetic ATaR updated successfully."
    else
      @versions = fetch_versions
      render :edit, status: :unprocessable_content
    end
  end

  def confirm_destroy
    authorize @synthetic_atar, :destroy?
  end

  def destroy
    authorize @synthetic_atar, :destroy?

    @synthetic_atar.destroy
    redirect_to tariff_knowledge_synthetic_atars_path, notice: "Synthetic ATaR deleted successfully."
  end

private

  def load_synthetic_atar
    @synthetic_atar = TariffKnowledgeSyntheticAtar.find(params[:id], params[:oid].present? ? { oid: params[:oid] } : {})
  end

  def redirect_synthetic_atar_not_found
    redirect_to tariff_knowledge_synthetic_atars_path, alert: "Synthetic ATaR not found."
  end

  def fetch_synthetic_atars
    TariffKnowledgeSyntheticAtar.all(params.permit(:page, :q, :chapter).to_h.symbolize_keys)
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch synthetic ATaRs: #{e.message}")
    flash.now[:alert] = "Synthetic ATaRs could not be loaded. Try again."
    Kaminari.paginate_array([]).page(1)
  end

  def fetch_versions
    Version.all(item_type: "TariffKnowledge::SyntheticAtar", item_id: @synthetic_atar.resource_id)
  rescue StandardError => e
    Rails.logger.error("Failed to fetch versions: #{e.message}")
    []
  end

  def synthetic_atar_params
    params.require(:tariff_knowledge_synthetic_atar).permit(
      :real_user_search,
      :chapter,
      :times_searched,
      :likely_heading,
      :description,
      :goods_nomenclature_item_id,
      :notes,
      :completed_by,
    )
  end
end
