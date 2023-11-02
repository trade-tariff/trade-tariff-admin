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
      redirect_to tariff_updates_path,
                  alert: "Unexpected error: #{error_messages_for(@download)}"
    end
  end

  def apply
    @apply = Apply.new
    @apply.user = current_user

    if @apply.valid? && @apply.save
      redirect_to tariff_updates_path, notice: 'Apply was scheduled'
    else
      redirect_to tariff_updates_path,
                  alert: "Unexpected error: #{error_messages_for(@apply)}"
    end
  end

  private

  def authorize_user
    authorize TariffUpdate, :access?
  end

  def error_messages_for(model)
    model.errors.full_messages.join(', ')
  end
end
