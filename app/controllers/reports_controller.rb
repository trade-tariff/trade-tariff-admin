class ReportsController < AuthenticatedController
  before_action :load_report, only: %i[show run download]

  def index
    authorize Report, :index?
    @reports = Report.all
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch reports: #{e.class} #{e.message}")
    @reports = []
    flash.now[:alert] = "Reports could not be loaded."
  end

  def show
    authorize @report, :show?
  end

  def run
    authorize @report, :run?
    @report.run

    redirect_to report_path(@report), notice: "Report generation was scheduled."
  rescue Faraday::Error => e
    Rails.logger.error("Failed to schedule report #{params[:id]}: #{e.class} #{e.message}")
    redirect_to report_path(@report), alert: "Failed to schedule report: #{e.message.truncate(200)}"
  end

  def download
    authorize @report, :show?

    download_url = @report.download_redirect_url
    redirect_to validated_download_url(download_url), allow_other_host: true
  rescue Faraday::Error => e
    Rails.logger.error("Failed to download report #{params[:id]}: #{e.class} #{e.message}")
    redirect_to report_path(@report), alert: "Failed to download report."
  rescue URI::InvalidURIError, ActionController::Redirecting::UnsafeRedirectError => e
    Rails.logger.error("Unsafe report download URL for #{params[:id]}: #{e.class} #{e.message}")
    redirect_to report_path(@report), alert: "Failed to download report."
  end

private

  def load_report
    @report = Report.find(params[:id])
  rescue Faraday::ResourceNotFound
    redirect_to reports_path, alert: "Report not found."
  end

  def validated_download_url(download_url)
    uri = URI.parse(download_url)
    expected_host = URI.parse(ENV.fetch("REPORTING_CDN_HOST", "https://reporting.trade-tariff.service.gov.uk")).host

    raise ActionController::Redirecting::UnsafeRedirectError, download_url unless uri.is_a?(URI::HTTPS)
    raise ActionController::Redirecting::UnsafeRedirectError, download_url unless uri.host == expected_host

    uri.to_s
  end
end
