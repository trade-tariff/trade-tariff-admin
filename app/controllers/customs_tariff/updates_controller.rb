module CustomsTariff
  class UpdatesController < AuthenticatedController
    def index
      authorize CustomsTariff::Update, :index?
      @updates = CustomsTariff::Update.all
    end

    def show
      @update = CustomsTariff::Update.find(params[:version])
      authorize @update, :show?
      @section_notes = CustomsTariff::SectionNote.all(customs_tariff_update_version: params[:version])
    end

    def update_status
      @update = CustomsTariff::Update.find(params[:version])
      authorize @update, :update?

      CustomsTariff::Update.api.patch(
        "admin/customs_tariff_updates/#{params[:version]}/status",
        { data: { attributes: { status: params.require(:status) } } },
      )

      redirect_to customs_tariff_update_path(params[:version]),
                  notice: "Status updated to #{params[:status]}."
    rescue Faraday::UnprocessableEntityError => e
      redirect_to customs_tariff_update_path(params[:version]),
                  alert: "Could not update status: #{e.response[:body].dig('errors', 0, 'detail')}"
    end
  end
end
