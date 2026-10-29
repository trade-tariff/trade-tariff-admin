# A read-only wrapper around GET /configuration — not an ApiEntity model (nothing here has an id or is
# ever saved), just a thin typed fetch the launch form's controller and view share.
class EvaluationConfiguration
  def self.schema
    response = TradeTariffAdmin::ServiceChooser.api_client("uk").get("admin/search/evaluation/configuration")
    body = response.body.is_a?(String) ? JSON.parse(response.body) : response.body

    # deep_symbolize_keys, not symbolize_keys: an "options" entry's own choices (question_model,
    # simulator_model) are a nested array of hashes, and the view reads their :key/:label with
    # symbol access too — a shallow symbolize would leave those as string-keyed JSON.parse output.
    #
    # search_index is what the backend says about the search index itself (today, how many documents hold
    # ATaR keywords). It stays string-keyed like the baseline, and nil, not an empty hash, when an older
    # backend sends none: "no report" and "a count that could not be made" mean different things to the form.
    { baseline: body["baseline"], allowed_overrides: body["allowed_overrides"].map(&:deep_symbolize_keys), search_index: body["search_index"] }
  end
end
