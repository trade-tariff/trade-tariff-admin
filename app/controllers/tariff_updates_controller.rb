class TariffUpdatesController < AuthenticatedController
  def index
    @tariff_updates = TariffUpdate.all(page: current_page).fetch
  end

  def show
    @tariff_update = TariffUpdate.find(params[:id])
  end
end
