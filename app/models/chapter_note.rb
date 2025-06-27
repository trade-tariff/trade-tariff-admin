class ChapterNote
  include ApiEntity

  validates :content, presence: true

  attr_accessor :content

  set_singular_path 'admin/chapters/:chapter_id/chapter_note'

  has_one :chapter

  def preview(...)
    Govspeak::Document.new(content, sanitize: true).to_html.html_safe
  end
end
