class SearchExportWorkbooksController < AuthenticatedController
  def create
    authorize SearchExportWorkbook, :create?

    export = SearchExportWorkbook.create(from: params[:from], to: params[:to])
    redirect_to search_export_workbook_path(export.resource_id)
  rescue Faraday::Error => e
    status = e.response_status.to_i
    raise unless [400, 422].include?(status)

    redirect_to search_analytics_path(view: "internal", period: "custom", from: params[:from], to: params[:to]), alert: error_detail(e)
  end

  def show
    authorize SearchExportWorkbook, :show?

    @export = SearchExportWorkbook.find(params[:id])
    response.set_header("Refresh", "2") if @export.pending?
  end

  def download
    authorize SearchExportWorkbook, :download?

    file = SearchExportWorkbook.download(params[:id])
    send_data file.body,
              filename: "classifier-workbook.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: "attachment"
  end

private

  def error_detail(error)
    body = error.response_body
    body = JSON.parse(body) if body.is_a?(String)
    body.is_a?(Hash) ? body.dig("errors", 0, "detail") || "Check the selected date range." : "Check the selected date range."
  rescue JSON::ParserError
    "Check the selected date range."
  end
end
