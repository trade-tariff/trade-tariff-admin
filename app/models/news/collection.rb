module News
  class Collection
    include Her::JsonApi::Model
    use_api Her::UK_API

    MAX_SLUG_LENGTH = 254

    collection_path '/admin/news/collections'

    attributes :id, :name, :description, :priority, :published, :slug

    before_validation :generate_or_normalise_slug!

    def id
      super&.to_i
    end

    private

    def generate_or_normalise_slug!
      current_slug = slug.presence || name.presence
      return unless current_slug

      normalised_slug = normalise_slug(slug.presence || name)
      self.slug = normalised_slug if slug != normalised_slug
    end

    def normalise_slug(slug)
      slug.downcase.gsub(/\s+/, '-').gsub(/[^a-z0-9-]/, '').first(MAX_SLUG_LENGTH)
    end
  end
end
