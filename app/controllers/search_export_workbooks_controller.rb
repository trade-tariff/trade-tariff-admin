class SearchExportWorkbooksController < AuthenticatedController
  def create
    authorize SearchExportWorkbook, :create?

    export = SearchExportWorkbook.create(from: params[:from], to: params[:to])
    redirect_to search_export_workbook_path(export.resource_id)
  rescue Faraday::Error => e
    status = e.response_status.to_i
    message = [400, 422].include?(status) ? error_detail(e) : "The workbook service is unavailable. Please try again."
    redirect_to search_analytics_path(view: "internal", period: "custom", from: params[:from], to: params[:to]), alert: message
  end

  def show
    authorize SearchExportWorkbook, :show?

    @export = SearchExportWorkbook.find(params[:id])
    polls = [params[:poll].to_i, 0].max
    @polling_stopped = @export.pending? && polls >= 90
    if @export.pending? && !@polling_stopped
      response.set_header("Refresh", "2; url=#{search_export_workbook_path(params[:id], poll: polls + 1)}")
    end
  rescue Faraday::ResourceNotFound
    render :not_found, status: :not_found
  rescue Faraday::Error
    render :unavailable, status: :service_unavailable
  end

  def download
    authorize SearchExportWorkbook, :download?

    export = SearchExportWorkbook.find(params[:id])
    file = SearchExportWorkbook.download(params[:id])
    send_data file.body,
              filename: "classifier-workbook-#{export.from}-#{export.to}.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: "attachment"
  rescue Faraday::ResourceNotFound
    render :not_found, status: :not_found
  rescue Faraday::Error
    render :unavailable, status: :service_unavailable
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
