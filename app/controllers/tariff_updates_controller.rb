class TariffUpdatesController < AuthenticatedController
  before_action :authorize_user if TradeTariffAdmin.authorization_enabled?

  def index
    @tariff_updates = Update.all(page: current_page)
  end

  def show
    @tariff_update = Update.find(params[:id])
  end

  def download
    @download = Download.build(user_id: current_user.id)
    @download.save

    redirect_to tariff_updates_path, notice: "Download was scheduled"
  rescue Faraday::Error => e
    redirect_to tariff_updates_path, alert: "Unexpected error: #{e}"
  end

  def resend_cds_update_notification
    @cds_update = CdsUpdateNotification.new(cds_update_params)
    @cds_update.save

    redirect_to tariff_updates_path, notice: "CDS Updates notification was scheduled"
  rescue Faraday::Error => e
    redirect_to tariff_updates_path, alert: "Unexpected error: #{e}"
  end

  def apply_and_clear_cache
    @apply = Apply.build(user_id: current_user.id)
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
      .merge(user_id: current_user.id)
  end

  def authorize_user
    authorize Update, :access?
  end

  def error_messages_for(model)
    model.errors.full_messages.join(", ")
  end
end
