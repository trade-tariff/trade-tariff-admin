class ReportsController < AuthenticatedController
  before_action :load_report, only: %i[show run]

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

private

  def load_report
    @report = Report.find(params[:id])
  rescue Faraday::ResourceNotFound
    redirect_to reports_path, alert: "Report not found."
  end
end
