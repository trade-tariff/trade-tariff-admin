require 'chapter/search_reference'

class Chapter
  include ApiEntity

  attr_accessor :chapter_note_id,
                :headings_from,
                :headings_to,
                :section_id,
                :description,
                :goods_nomenclature_item_id

  has_one :section
  has_one :chapter_note
  has_many :headings

  def search_references(page: 1, per_page: 5)
    Chapter::SearchReference.all(casted_by: self, page:, per_page:)
  end

  def has_chapter_note?
    chapter_note_id.present?
  end

  def short_code
    goods_nomenclature_item_id&.first(2)
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
    goods_nomenclature_item_id
  end
end
