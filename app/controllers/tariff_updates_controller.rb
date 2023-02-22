class TariffUpdatesController < AuthenticatedController
  before_action :authorize_user

  def index
    @tariff_updates = TariffUpdate.all(page: current_page).fetch
  end

  def show
    @tariff_update = TariffUpdate.find(params[:id])
  end

  private

  def authorize_user
    authorize TariffUpdate, :access?
  end
end
