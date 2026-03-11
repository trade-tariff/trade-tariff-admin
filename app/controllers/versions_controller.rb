class VersionsController < AuthenticatedController
  include VersionsHelper

  def index
    authorize Version, :index?

    @versions = Version.all(version_params)
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch versions: #{e.message}")
    @versions = []
  end

  def restore
    authorize Version, :restore?

    response = Version.api.post("admin/versions/#{params[:id]}/restore")
    version_data = response.body["data"]
    restored = Version.new((version_data["attributes"] || {}).merge("id" => version_data["id"])) if version_data

    redirect_to (restored && version_item_link(restored)) || versions_path,
                notice: "Restored successfully."
  rescue Faraday::ResourceNotFound
    redirect_to versions_path, alert: "Version not found."
  rescue Faraday::Error => e
    redirect_to versions_path, alert: "Failed to restore: #{e.message.truncate(200)}"
  end

private

  def version_params
    filter = { page: params[:page] || 1 }
    filter[:item_type] = params[:item_type] if params[:item_type].present?
    filter[:event] = event_filter if event_filter.present?
    filter[:exclude_item_type] = %w[ChapterNote SectionNote] if params[:item_type].blank?
    filter
  end

  def event_filter
    # Default to "update" on first visit; empty string means "all events"
    return params[:event] if params.key?(:event)

    "update"
  end
  helper_method :event_filter
end
