require 'section/search_reference'

class Section
  include Her::JsonApi::Model

  collection_path '/admin/sections'

  has_one :section_note, class_name: 'SectionNote'
  has_many :chapters
  has_many :search_references, class_name: 'Section::SearchReference'

  attributes :chapter_from, :chapter_to, :numeral

  def has_section_note?
    section_note_id.present?
  end

  def chapter_from=(chapter_from)
    attributes[:chapter_from] = chapter_from.to_i
  end

  def chapter_to=(chapter_to)
    attributes[:chapter_to] = chapter_to.to_i
  end

  def chapters_range
    if chapter_from == chapter_to
      chapter_from
    else
      "#{chapter_from} to #{chapter_to}"
    end
  end

  def export_filename
    "#{self.class.name.tableize}-#{position}-synonyms-#{Time.zone.now.iso8601}.csv"
  end

  def reference_title
    "Section (#{position})"
  end

  def to_param
    # beckend app uses position to fetch section
    # id.to_s
    position.to_s
  end

  def to_s
    title
  end
end
