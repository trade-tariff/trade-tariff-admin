require 'chapter/search_reference'

class Chapter
  include Her::JsonApi::Model

  collection_path '/admin/chapters'

  attributes :chapter_note_id, :headings_from, :headings_to, :section_id, :goods_nomenclature_item_id

  has_one :chapter_note, class_name: 'ChapterNote'
  has_many :headings
  has_many :search_references, class_name: 'Chapter::SearchReference'
  has_one :section

  def has_chapter_note?
    chapter_note_id.present?
  end

  def short_code
    goods_nomenclature_item_id.first(2)
  end

  def headings_range
    if headings_from == headings_to
      headings_from
    else
      "#{headings_from} to #{headings_to}"
    end
  end

  def headings_from=(headings_from)
    attributes[:headings_from] = headings_from.last(2).to_i
  end

  def headings_to=(headings_to)
    attributes[:headings_to] = headings_to.last(2).to_i
  end

  def id
    short_code
  end

  def export_filename
    "#{self.class.name.tableize}-#{short_code}-references-#{Time.zone.now.iso8601}.csv"
  end

  def reference_title
    "Chapter (#{short_code})"
  end

  def to_param
    short_code.to_s
  end

  def to_s
    goods_nomenclature_item_id
  end

  def request_path(_opts = {})
    self.class.build_request_path("/admin/chapters/#{to_param}", attributes.dup)
  end
end
