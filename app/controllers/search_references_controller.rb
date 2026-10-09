class SearchReferencesController < AuthenticatedController
  def show
    authorize SearchReference, :show?

    @search_reference = SearchReference.find(params[:id], params[:oid].present? ? { oid: params[:oid] } : {})
    @versions = fetch_versions
  rescue Faraday::ResourceNotFound
    redirect_to versions_path(item_type: "SearchReference"), alert: "Search reference not found."
  end

private

  def fetch_versions
    Version.all(item_type: "SearchReference", item_id: params[:id])
  rescue StandardError => e
    Rails.logger.error("Failed to fetch versions: #{e.message}")
    []
  end
end
