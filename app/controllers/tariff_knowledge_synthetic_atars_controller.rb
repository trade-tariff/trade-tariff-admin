class TariffKnowledgeSyntheticAtarsController < AuthenticatedController
  # The analysts' workbook has several tabs. The data is on this one.
  IMPORT_SHEET_NAME = "Classifications".freeze
  EXAMPLE_IMPORT_HEADERS = [
    "Chapter",
    "Real user search",
    "Times searched",
    "Likely heading",
    "Full product description",
    "Commodity code (10 digits)",
    "Status",
    "Completed by",
    "Notes",
  ].freeze

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

  def import
    authorize TariffKnowledgeSyntheticAtar, :create?
  end

  def bulk_import
    authorize TariffKnowledgeSyntheticAtar, :create?

    file_result = SpreadsheetImportFile.new(import_file, sheet_name: IMPORT_SHEET_NAME).call
    if file_result.success?
      import_result = TariffKnowledgeSyntheticAtar.bulk_import(file_result.csv_content)
      return redirect_to tariff_knowledge_synthetic_atars_path, notice: import_result.message if import_result.success?

      @import_errors = import_result.errors
    else
      @import_errors = file_result.errors
    end

    render :import, status: :unprocessable_content
  end

  def example_import
    authorize TariffKnowledgeSyntheticAtar, :index?

    send_data CSV.generate_line(EXAMPLE_IMPORT_HEADERS),
              filename: "synthetic-atars-example.csv",
              type: "text/csv"
  end

private

  def import_file
    params.dig(:tariff_knowledge_synthetic_atar_import, :file)
  end

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
