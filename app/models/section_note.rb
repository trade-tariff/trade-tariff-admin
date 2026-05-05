class SectionNote
  include ApiEntity

  validates :content, presence: true

  attr_accessor :content

  set_singular_path "admin/sections/:section_id/section_note"

  has_one :section

  def section_title; end

  def preview(field_name = :content, **options)
    content = public_send(field_name)
    GovspeakPreview.new(content, **options).render if content.present?
  end
end
