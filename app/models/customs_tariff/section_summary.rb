module CustomsTariff
  class SectionSummary
    include ApiEntity

    attributes :section_id, :section_title, :position,
               :section_note_id, :section_note_status,
               :chapter_notes_total, :chapter_notes_changed

    set_singular_path   "admin/customs_tariff_updates/:customs_tariff_update_version/sections_summary"
    set_collection_path "admin/customs_tariff_updates/:customs_tariff_update_version/sections_summary"

    def section_note_status_symbol
      section_note_status&.to_sym
    end

    def chapter_notes_changed?
      chapter_notes_changed.to_i.positive?
    end

    def chapter_note_summary_label
      return "Unchanged" unless chapter_notes_changed?

      "#{chapter_notes_changed} changed"
    end
  end
end
