class SectionNote
  include ApiEntity

  validates :content, presence: true

  attr_accessor :content

  set_singular_path "admin/sections/:section_id/section_note"

  has_one :section

  def section_title; end

  def preview(...)
    Govspeak::Document.new(content, sanitize: true).to_html.html_safe
  end
end
