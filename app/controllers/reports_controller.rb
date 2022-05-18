class ReportsController < AuthenticatedController
  def index; end

  def show
    respond_to do |format|
      format.csv do
        send_data(
          report.csv_data,
          type: 'text/csv; charset=utf-8; header=present',
          disposition: "attachment; filename=#{report.filename}",
        )
      end
    end
  end

  def report
    @report ||= Report.build(params[:id].to_s)
  end
end
