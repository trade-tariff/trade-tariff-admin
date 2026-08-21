module News
  class Item
    include ApiEntity

    uk_only

    DISPLAY_STYLE_REGULAR = 0
    MAX_SLUG_LENGTH = 254

    attributes :title,
               :slug,
               :precis,
               :content,
               :display_style,
               :show_on_uk,
               :show_on_xi,
               :show_on_home_page,
               :show_on_updates_page,
               :show_on_banner,
               :start_date,
               :end_date,
               :chapters,
               :notify_subscribers,
               :created_at,
               :updated_at

    def collection_ids
      @collection_ids ||= []
    end

    def collection_ids=(ids)
      @collection_ids = Array(ids).map(&:presence).compact.uniq.map(&:to_i)
    end

    def preview(field_name = nil, **options)
      markdown = field_name.to_s == "precis" ? precis : content

      GovspeakPreview.new(markdown, **options).render
    end

    def start_date=(value)
      @start_date = normalise_date(value)
    end

    def end_date=(value)
      @end_date = normalise_date(value)
    end

    def start_date
      initialise_date!(@start_date, use_today: true)
    end

    def end_date
      initialise_date!(@end_date)
    end

    def generate_or_normalise_slug!
      current_slug = slug.presence || title.presence
      return unless current_slug

      normalised_slug = normalise_slug(slug.presence || title)
      self.slug = normalised_slug if slug != normalised_slug
    end

  private

    def normalise_slug(slug)
      slug.downcase.gsub(/\s+/, "-").gsub(/[^a-z0-9-]/, "").first(MAX_SLUG_LENGTH)
    end

    def normalise_date(date)
      date.is_a?(Date) ? date.to_s : date
    end

    def initialise_date!(date, use_today: false)
      if date.is_a?(Date)
        date
      elsif date
        Date.parse(date)
      else
        use_today ? Time.zone.today : nil
      end
    rescue StandardError
      # reset the input fields to nil
      Rails.logger.debug("Received invalid date: #{date}")
      nil
    end
  end
end
