module Synonyms
  class ExportsController < AuthenticatedController
    def create
      export_service = SearchReference::ExportAllService.new
      filename = "all-synonyms-#{Time.zone.now.to_i}.csv"
      send_data export_service.to_csv,
                filename: filename
    end
  end
end
