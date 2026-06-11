class SearchAnalyticsController < AuthenticatedController
  ZERO_SEARCH_TERM_FILTERS = %w[search_terms item_ids].freeze
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
    @improvement_terms = Kaminari
      .paginate_array(filtered_terms)
      .page(params.fetch(:page, 1))
      .per(IMPROVEMENT_TERMS_PER_PAGE)
  end

  def normalised_term_filter
    filter = params.fetch(:term_filter, "search_terms")

    ZERO_SEARCH_TERM_FILTERS.include?(filter) ? filter : "search_terms"
  end

  def filter_improvement_terms(terms)
    case @term_filter
    when "item_ids"
      terms.select { |term| item_id_query?(term) }
    when "search_terms"
      terms.reject { |term| item_id_query?(term) }
    else
      terms
    end
  end

  def item_id_query?(term)
    term = term.with_indifferent_access

    return term[:term_type] == "item_ids" if term[:term_type].present?

    term.fetch(:query, "").to_s.match?(/\A[\d\s.-]+\z/)
  end
end
