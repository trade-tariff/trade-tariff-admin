class SearchAnalyticsController < AuthenticatedController
  IMPROVEMENT_TERM_FILTERS = %w[all non_numeric numeric].freeze
  IMPROVEMENT_TERMS_PER_PAGE = 10

  def index
    authorize SearchAnalytics, :index?

    @period = params.fetch(:period, "24h")
    @view = params.fetch(:view, "all")
    @search_analytics = SearchAnalytics.fetch(period: @period, view: @view)
    prepare_improvement_terms
  rescue Faraday::ResourceNotFound
    render_unavailable_dashboard("Search analytics are not available yet.")
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch search analytics: #{e.class} #{e.message}")
    render_unavailable_dashboard("Search analytics could not be loaded.")
  end

private

  def render_unavailable_dashboard(message)
    flash.now[:alert] = message
    @search_analytics = SearchAnalytics.new(period: @period, view: @view)
    prepare_improvement_terms

    render :index
  end

  def prepare_improvement_terms
    @term_filter = normalised_term_filter
    filtered_terms = filter_improvement_terms(Array(@search_analytics.improvement_terms))
    @term_total_pages = [(filtered_terms.size.to_f / IMPROVEMENT_TERMS_PER_PAGE).ceil, 1].max
    @term_page = [[params.fetch(:term_page, 1).to_i, 1].max, @term_total_pages].min
    @improvement_terms = filtered_terms.slice((@term_page - 1) * IMPROVEMENT_TERMS_PER_PAGE, IMPROVEMENT_TERMS_PER_PAGE) || []
  end

  def normalised_term_filter
    filter = params.fetch(:term_filter, "all")

    IMPROVEMENT_TERM_FILTERS.include?(filter) ? filter : "all"
  end

  def filter_improvement_terms(terms)
    case @term_filter
    when "numeric"
      terms.select { |term| numeric_search_term?(term) }
    when "non_numeric"
      terms.reject { |term| numeric_search_term?(term) }
    else
      terms
    end
  end

  def numeric_search_term?(term)
    term.with_indifferent_access.fetch(:query, "").to_s.match?(/\A[\d\s.-]+\z/)
  end
end
