module References
  class ExportsController < AuthenticatedController
    def show
      authorize SearchReference, :export?
      @export = References::Export.new
    end

    def download
      authorize SearchReference, :export?
      include_ai_labels = ActiveModel::Type::Boolean.new.cast(params[:include_ai_labels]) || false
      authorize SearchReference, :export_ai_labels? if include_ai_labels
      file = SearchReference.export(include_ai_labels:)

      send_data file.body,
                filename: "search_references_#{TradeTariffAdmin::ServiceChooser.service_name}_#{Time.zone.today.strftime('%Y_%m_%d')}.csv",
                type: "text/csv",
                disposition: "attachment"
    rescue Faraday::Error => e
      Rails.logger.error("Failed to download search references export: #{e.class} #{e.message}")
      redirect_to references_export_path, alert: "Search references export failed"
    end
  end
end
