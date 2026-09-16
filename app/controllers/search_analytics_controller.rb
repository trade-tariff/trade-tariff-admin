class SearchAnalyticsController < AuthenticatedController
  ZERO_SEARCH_TERM_FILTERS = %w[search_terms item_ids].freeze
  IMPROVEMENT_TERMS_PER_PAGE = 10

  def index
    authorize SearchAnalytics, :index?

    prepare_filters
    @search_analytics = SearchAnalytics.fetch(**@analytics_params)
    prepare_improvement_terms
  rescue Faraday::BadRequestError => e
    render_unavailable_dashboard(date_range_error(e), status: :unprocessable_entity)
  rescue Faraday::ResourceNotFound
    render_unavailable_dashboard("No collected search analytics are available for the selected dates.")
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch search analytics: #{e.class} #{e.message}")
    render_unavailable_dashboard("Search analytics could not be loaded.")
  end

private

  def prepare_filters
    @period = %w[24h 7d 30d custom].include?(params[:period]) ? params[:period] : "24h"
    @view = %w[all classic internal].include?(params[:view]) ? params[:view] : "all"
    @latest_date = (Time.current.utc.to_date - 1).iso8601
    custom = params.key?(:from) || params.key?(:to) || @period == "custom"
    @period = "custom" if custom
    dates = custom ? { from: params[:from], to: params[:to] } : {}
    @analytics_params = { period: @period, view: @view }.merge(dates)
    @to = custom ? params[:to] : @latest_date
    @from = custom ? params[:from] : (Date.iso8601(@latest_date) - { "7d" => 6, "30d" => 29 }.fetch(@period, 0)).iso8601
  end

  def date_range_error(error)
    body = error.response_body
    body = JSON.parse(body) if body.is_a?(String)
    body.is_a?(Hash) ? body.dig("errors", 0, "detail") || "Check the selected date range." : "Check the selected date range."
  rescue JSON::ParserError
    "Check the selected date range."
  end

  def render_unavailable_dashboard(message, status: :ok)
    flash.now[:alert] = message
    @analytics_unavailable = true
    @search_analytics = SearchAnalytics.new(period: @period, view: @view)
    prepare_improvement_terms

    render :index, status:
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
