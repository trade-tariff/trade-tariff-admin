module CustomsTariff
  class ChapterNote
    include ApiEntity

    attributes :chapter_id, :content, :customs_tariff_update_version, :file_diff, :versions

    set_singular_path   "admin/customs_tariff_updates/:customs_tariff_update_version/chapter_notes/:id"
    set_collection_path "admin/customs_tariff_updates/:customs_tariff_update_version/chapter_notes"

    def file_diff_status
      return :new       if file_diff.nil?
      return :unchanged if file_diff.respond_to?(:empty?) && file_diff.empty?

      :changed
    end

    def has_changeset?
      file_diff_status == :changed
    end

    def changes
      return {} unless file_diff.is_a?(Hash)

      file_diff["changes"] || {}
    end

    def preview
      return if content.blank?

      GovspeakPreview.new(TariffNoteFormatter.new(content).format).render
    end

    def version_objects
      @version_objects ||= (versions || []).map { |v| Version.new(v.merge("resource_id" => v["id"])) }
    end
  end
end
