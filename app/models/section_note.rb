class SectionNote
  include ApiEntity

  validates :content, presence: true

  attr_accessor :content

  set_singular_path "admin/sections/:section_id/section_note"

  has_one :section

  def section_title; end

  def preview(field_name = :content, **options)
    content = public_send(field_name)
    return if content.blank?

    GovspeakPreview.new(TariffNoteFormatter.new(content).format, **options).render
  end
end
