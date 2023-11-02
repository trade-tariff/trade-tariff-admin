class TariffUpdatesController < AuthenticatedController
  before_action :authorize_user

  def index
    @tariff_updates = TariffUpdate.all(page: current_page).fetch
  end

  def show
    @tariff_update = TariffUpdate.find(params[:id])
  end

  def download
    @download = Download.new
    @download.user = current_user

    if @download.valid? && @download.save
      redirect_to tariff_updates_path, notice: 'Download was scheduled'
    else
      render :new
    end
  end

  def apply

  end

  private

  def authorize_user
    authorize TariffUpdate, :access?
  end
end
