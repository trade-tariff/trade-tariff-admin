# Shows which set an experiment or a run is scored against. Both come from the backend with
# source_type (which kind of set) and source_name, and with the id of each kind of set to link to.
module EvaluationSourcesHelper
  SOURCE_KIND_LABELS = {
    "gold_query_set" => "Gold query set",
    "synthetic_input_set" => "Synthetic input set",
  }.freeze

  # The set's name linked to its own page, with the kind of set underneath.
  def evaluation_source(record)
    return "None chosen" if record.source_type.blank?

    path = if record.source_type == "gold_query_set"
             evaluation_gold_query_set_path(record.gold_query_set_id)
           else
             evaluation_synthetic_input_set_path(record.synthetic_input_set_id)
           end

    safe_join([
      link_to(record.source_name, path, class: "govuk-link"),
      tag.br,
      tag.span(SOURCE_KIND_LABELS.fetch(record.source_type, record.source_type.humanize), class: "govuk-hint govuk-!-margin-bottom-0"),
    ])
  end
end
