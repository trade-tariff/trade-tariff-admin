class TariffUpdatesController < AuthenticatedController
  def index
    authorize Update, :index?
    @tariff_updates = Update.all(page: current_page)
  end

  def show
    @tariff_update = Update.find(params[:id])
    authorize @tariff_update, :show?
  end

  def download
    authorize Update, :schedule_download?
    @download = Download.build
    @download.save

    redirect_to tariff_updates_path, notice: "Download was scheduled"
  rescue Faraday::Error => e
    redirect_to tariff_updates_path, alert: "Unexpected error: #{e}"
  end

  def resend_cds_update_notification
    authorize Update, :resend_cds_update_notification?
    @cds_update = CdsUpdateNotification.new(cds_update_params)
    @cds_update.save

    redirect_to tariff_updates_path, notice: "CDS Updates notification was scheduled"
  rescue Faraday::Error => e
    redirect_to tariff_updates_path, alert: "Unexpected error: #{e}"
  end

  def apply_and_clear_cache
    authorize Update, :apply_and_clear_cache?
    @apply = Apply.build
    @apply.save

    redirect_to tariff_updates_path, notice: "Apply & ClearCache was scheduled"
  rescue Faraday::Error => e
    redirect_to tariff_updates_path, alert: "Unexpected error: #{e}"
  end

private

  def cds_update_params
    params
      .require(:cds_update_notification)
      .permit(:filename)
      .to_h
  end
end
