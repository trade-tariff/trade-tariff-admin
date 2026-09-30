module EvaluationGoldQuerySetsHelper
  STATUS_TAGS = {
    "generating" => { text: "Generating", colour: "blue" },
    "ready" => { text: "Ready", colour: "green" },
    "partly_failed" => { text: "Partly failed", colour: "yellow" },
    "failed" => { text: "Failed", colour: "red" },
  }.freeze

  def gold_query_set_status_tag(gold_query_set)
    tag = STATUS_TAGS.fetch(gold_query_set.status.to_s) { { text: gold_query_set.status.to_s.humanize, colour: "grey" } }

    govuk_tag(text: tag[:text], colour: tag[:colour])
  end

  # "37 of 40 done, 2 failed". Counts source items, not the three queries of each item.
  def gold_query_set_progress(gold_query_set)
    text = "#{gold_query_set.finished_count} of #{gold_query_set.planned_count} done"
    text += ", #{gold_query_set.failed_count} failed" if gold_query_set.failed_count.to_i.positive?
    text
  end

  def gold_query_source_label(source_type)
    { "atar" => "ATaR", "synthetic_atar" => "Synthetic ATaR" }.fetch(source_type.to_s, source_type.to_s.humanize)
  end
end
