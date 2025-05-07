module News
  class Collection
    include ApiEntity

    uk_only

    MAX_SLUG_LENGTH = 254

    attributes :name,
               :description,
               :priority,
               :published,
               :slug

    def generate_or_normalise_slug!
      current_slug = slug.presence || name.presence
      return unless current_slug

      normalised_slug = normalise_slug(slug.presence || name)
      self.slug = normalised_slug if slug != normalised_slug
    end

    private

    def normalise_slug(slug)
      slug.downcase.gsub(/\s+/, '-').gsub(/[^a-z0-9-]/, '').first(MAX_SLUG_LENGTH)
    end
  end
end
