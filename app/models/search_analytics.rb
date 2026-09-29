class SearchAnalytics
  include ApiEntity

  attributes :service,
             :period,
             :view,
             :bucket_size,
             :generated_at,
             :data_through,
             :summary,
             :actions,
             :journeys,
             :coverage,
             :availability,
             :summary_statuses,
             :trends,
             :comparisons,
             :request_sources,
             :ai_costs,
             :frontend_events,
             :outcome_rates,
             :question_outcomes,
             :suggestions,
             :improvement_terms

  set_collection_path "admin/search_analytics"

  def self.fetch(period:, view:, from: nil, to: nil)
    response = api.get(collection_path, { period:, view:, from:, to: }.compact)
    new(parse_jsonapi(response))
  end
end
