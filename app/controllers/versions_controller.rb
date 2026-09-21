class VersionsController < AuthenticatedController
  include VersionsHelper

  # A restore writes the record that the version belongs to. It must obey the
  # same rule as a direct edit of that record. This map gives the policy of
  # each item type that the Admin Portal can restore. Each entry is the policy
  # that the edit screen for that item type uses.
  #
  # An item type that is not in the map falls back to ApplicationPolicy, which
  # denies every action. GoodsNomenclatureIntercept is deliberately absent: the
  # backend can restore that type, but the Admin Portal has no screen for it,
  # so no role may restore one from here.
  RESTORE_POLICIES = {
    "AdminConfiguration" => AdminConfigurationPolicy,
    "GoodsNomenclatureLabel" => GoodsNomenclatureLabelPolicy,
    "GoodsNomenclatureSelfText" => GoodsNomenclatureSelfTextPolicy,
    "TariffKnowledge::CompressedNote" => TariffKnowledgeCompressedNotePolicy,
    "DescriptionIntercept" => DescriptionInterceptPolicy,
    "CustomsTariffSectionNote" => CustomsTariff::SectionNotePolicy,
    "CustomsTariffChapterNote" => CustomsTariff::ChapterNotePolicy,
  }.freeze

  def index
    authorize Version, :index?

    @versions = Version.all(version_params)
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch versions: #{e.message}")
    @versions = []
  end

  def restore
    version = Version.find(params[:id])
    authorize version, :update?, policy_class: RESTORE_POLICIES.fetch(version.item_type, ApplicationPolicy)

    response = Version.api.post("admin/versions/#{params[:id]}/restore")
    version_data = response.body["data"]
    restored = Version.new((version_data["attributes"] || {}).merge("id" => version_data["id"])) if version_data

    redirect_to chapter_note_restore_path || (restored && version_item_link(restored)) || versions_path,
                notice: "Restored successfully."
  rescue Faraday::ResourceNotFound
    # The lookup can fail before authorize runs. There is then no record to
    # authorise against, so tell Pundit that this request needs no policy.
    skip_authorization
    redirect_to versions_path, alert: "Version not found."
  rescue Faraday::Error => e
    skip_authorization
    redirect_to versions_path, alert: "Failed to restore: #{e.message.truncate(200)}"
  end

private

  def chapter_note_restore_path
    return unless params[:section_id].present? && params[:update_version].present?

    customs_tariff_update_section_chapter_notes_path(params[:update_version], params[:section_id])
  end

  def version_params
    filter = { page: params[:page] || 1 }
    filter[:item_type] = params[:item_type] if params[:item_type].present?
    filter[:event] = event_filter if event_filter.present?
    filter[:exclude_item_type] = %w[ChapterNote SectionNote CustomsTariffSectionNote] if params[:item_type].blank?
    filter
  end

  def event_filter
    # Default to "update" on first visit; empty string means "all events"
    return params[:event] if params.key?(:event)

    "update"
  end
  helper_method :event_filter
end
