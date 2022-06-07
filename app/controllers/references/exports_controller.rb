module References
  class ExportsController < AuthenticatedController
    def create
      export_service = SearchReference::ExportAllService.new
      filename = "all-references-#{Time.zone.now.iso8601}.csv"
      send_data export_service.to_csv,
                filename:
    end
  end
end
