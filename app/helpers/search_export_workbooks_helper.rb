module SearchExportWorkbooksHelper
  def workbook_date_label(export, preset)
    from = Date.iso8601(export.from)
    to = Date.iso8601(export.to)
    days = { "24h" => 1, "7d" => 7, "30d" => 30 }[preset]
    if days && to == Time.current.utc.to_date - 1 && from == to - days + 1
      return preset == "24h" ? "Last 24 hours" : "Last #{days} days"
    end

    return "For #{from.to_formatted_s(:govuk)}" if from == to

    "#{from.to_formatted_s(:govuk)} to #{to.to_formatted_s(:govuk)}"
  end
end
