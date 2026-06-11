class SearchAnalytics
  include ApiEntity

  attributes :service,
             :period,
             :view,
             :bucket_size,
             :generated_at,
             :data_through,
             :summary,
             :summary_statuses,
             :trends,
             :comparisons,
             :suggestions,
             :improvement_terms

  set_collection_path "admin/search_analytics"

  def self.fetch(period:, view:)
    response = api.get(collection_path, { period:, view: })
    new(parse_jsonapi(response))
  end
end
