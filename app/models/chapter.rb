require "chapter/search_reference"

class Chapter
  include ApiEntity

  has_one :section
  has_one :chapter_note
  has_many :headings

  def search_references
    Chapter::SearchReference.all(casted_by: self)
  end

  def has_chapter_note?
    self[:chapter_note_id].present?
  end

  def short_code
    self[:goods_nomenclature_item_id]&.first(2)
  end

  def headings_range
    if headings_from == headings_to
      headings_from
    else
      "#{headings_from} to #{headings_to}"
    end
  end

  alias_method :id, :short_code

  def reference_title
    "Chapter (#{short_code})"
  end

  def to_param
    short_code.to_s.presence || resource_id
  end

  def to_s
    self[:goods_nomenclature_item_id]
  end
end
