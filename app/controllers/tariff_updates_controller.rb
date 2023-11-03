class TariffUpdatesController < AuthenticatedController
  before_action :authorize_user

  def index
    @tariff_updates = TariffUpdate.all(page: current_page).fetch
  end

  def show
    @tariff_update = TariffUpdate.find(params[:id])
  end

  def download
    @download = Download.new(user: current_user)
    @download.save

    redirect_to tariff_updates_path, notice: 'Download was scheduled'
  rescue Faraday::Error => e
    redirect_to tariff_updates_path, alert: "Unexpected error: #{e}"
  end

  def apply
    @apply = Apply.new(user: current_user)
    @apply.save

    redirect_to tariff_updates_path, notice: 'Apply was scheduled'
  rescue Faraday::Error => e
    redirect_to tariff_updates_path, alert: "Unexpected error: #{e}"
  end

  private

  def authorize_user
    authorize TariffUpdate, :access?
  end

  def error_messages_for(model)
    model.errors.full_messages.join(', ')
  end
end
