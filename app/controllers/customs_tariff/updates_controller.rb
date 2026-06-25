module CustomsTariff
  class UpdatesController < AuthenticatedController
    def index
      authorize CustomsTariff::Update, :index?
      @updates = CustomsTariff::Update.all(page: current_page)
    end

    def show
      @update = CustomsTariff::Update.find(params[:version])
      authorize @update, :show?
      @updates = CustomsTariff::Update.all
      @section_summaries = CustomsTariff::SectionSummary.all(customs_tariff_update_version: params[:version])
      @sections_by_id = Section.all.index_by { |s| s.position.to_i }
      @baseline_version = @updates
        .reject { |u| u.version == @update.version || u.status == "failed" }
        .select { |u| u.validity_start_date.present? && u.validity_start_date < @update.validity_start_date }
        .max_by(&:validity_start_date)
        &.version
    end

    def reimport
      @update = CustomsTariff::Update.find(params[:version])
      authorize @update, :update?

      CustomsTariff::Update.api.post(
        "admin/customs_tariff_updates/#{params[:version]}/reimport",
      )

      redirect_to customs_tariff_updates_path, notice: "Re-import queued."
    rescue Faraday::ResourceNotFound
      redirect_to customs_tariff_updates_path, alert: "Update could not be found."
    end
  end
end
