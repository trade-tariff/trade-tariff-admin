class Section
  include ApiEntity

  has_many :chapters

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

  def to_s
    title
  end
end
