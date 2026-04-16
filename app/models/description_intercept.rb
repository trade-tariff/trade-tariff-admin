class DescriptionIntercept
  include ApiEntity

  GUIDANCE_LEVELS = %w[info warning error].freeze
  GUIDANCE_LOCATIONS = %w[interstitial results question].freeze
  SOURCES = %w[guided_search fpo_search].freeze
  SOURCE_LABELS = {
    "guided_search" => "Guided search",
    "fpo_search" => "FPO search",
  }.freeze

  attributes :term,
             :message,
             :guidance_level,
             :guidance_location,
             :filter_prefixes,
             :sources,
             :created_at

  boolean_attributes :excluded,
                     :escalate_to_webchat

  def normalize_serialized_attributes(attrs)
    # The form hides guidance and filter controls depending on the selected
    # search behaviour. Send one canonical payload for new and existing records:
    # blank guidance is explicit nils, and disabled filtering is an empty array.
    if attrs[:message].blank?
      attrs[:message] = nil
      attrs[:guidance_level] = nil
      attrs[:guidance_location] = nil
    end

    attrs[:filter_prefixes] = [] if attrs[:excluded] || Array(attrs[:filter_prefixes]).reject(&:blank?).empty?
  end

  def self.listing(params)
    filters = params.permit(:page, :q, :excluded, :guidance, :escalates, :filtering).to_h.symbolize_keys
    records = all(filters)

    {
      data: records.map(&:as_listing_json),
      pagination: pagination_for(records),
    }
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch description intercepts: #{e.message}")
    { data: [], pagination: { page: 1, per_page: 20, total_count: 0, total_pages: 0 } }
  end

  def as_listing_json
    {
      id: resource_id,
      term: term,
      excluded: excluded?,
      guidance: message.to_s.truncate(80),
      guidance_present: guidance?,
      filtering: filtering?,
      behaviour: behaviour_summary,
      escalates: escalate_to_webchat?,
      created_at: formatted_created_at,
    }
  end

  def guidance?
    message.present?
  end

  def filtering?
    filter_prefixes.present?
  end

  def formatted_created_at
    return "-" if created_at.blank?

    date = Date.parse(created_at.to_s)
    date == Date.current ? "Today" : date.to_formatted_s(:govuk)
  rescue ArgumentError
    created_at.to_s
  end

  def behaviour_summary
    return "Excludes search results" if excluded?
    return "Filters to selected short codes" if filtering?

    "No search override"
  end

  def excluded_tag_colour
    excluded? ? "red" : "grey"
  end

  def escalation_tag_colour
    escalate_to_webchat? ? "blue" : "grey"
  end

  def location_label
    guidance_location.to_s.humanize.presence || "-"
  end

  def level_label
    guidance_level.to_s.humanize.presence || "-"
  end

  def sources_label
    Array(sources).map { |source| SOURCE_LABELS[source] || source.to_s.humanize }.join(", ").presence || "-"
  end

  def filter_prefixes_label
    Array(filter_prefixes).join(", ").presence || "-"
  end
end
