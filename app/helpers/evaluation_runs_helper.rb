module EvaluationRunsHelper
  MINIMUM_FINISHED_FOR_ESTIMATE = 3
  SLOW_RUN_THRESHOLD = 5.minutes

  # nil when there isn't enough data yet to say anything useful — just started, already done, or
  # started_at is missing/unparseable (the backend sets it the moment a run enters "running"; a run
  # the eval app hasn't picked up yet has none, same as a malformed one — both mean "don't guess").
  def evaluation_run_eta(run, total_items)
    return nil unless run.finished_count >= MINIMUM_FINISHED_FOR_ESTIMATE
    return nil unless total_items > run.finished_count

    elapsed = evaluation_run_elapsed(run)
    return nil unless elapsed

    seconds_per_item = elapsed / run.finished_count
    remaining_items = total_items - run.finished_count
    minutes = ((seconds_per_item * remaining_items) / 60.0).ceil

    "About #{pluralize(minutes, 'minute')} remaining"
  end

  def evaluation_run_running_a_while?(run)
    elapsed = evaluation_run_elapsed(run)
    elapsed.present? && elapsed > SLOW_RUN_THRESHOLD
  end

  def evaluation_run_rate(rate)
    rate.nil? ? "-" : "#{rate.round}%"
  end

  def evaluation_run_seconds(seconds)
    seconds.nil? ? "-" : "#{sprintf('%.1f', seconds)}s"
  end

  def evaluation_run_average(total, count)
    return "-" if count.to_i.zero?

    sprintf("%.4f", total.to_f / count)
  end

  # outlier is one of :max_cost_result, :min_cost_result, :max_latency_result, :min_latency_result —
  # each a small nested hash (or nil) the run's own serializer already computed. value_field names
  # which of that hash's two numeric fields (cost_usd or latency_seconds) this particular row cares
  # about; the other field exists in the same hash but isn't shown here, since a "most expensive"
  # row showing its own latency too would be more noise than signal. source_type matters here the
  # same way it does on the results list — a synthetic ATaR's source_id is its own small database
  # id (e.g. "8"), indistinguishable from any other short id without the type label alongside it.
  def evaluation_run_outlier_link(run, outlier, value_field)
    result = run.public_send(outlier)
    return "-" if result.nil?

    value = "#{value_field == 'cost_usd' ? '$' : ''}#{result[value_field]}#{value_field == 'latency_seconds' ? 's' : ''}"
    label = "#{gold_query_source_label(result['source_type'])} #{result['source_id']} (#{result['expected_code']}, #{value})"
    link_to label, evaluation_run_result_path(run, result["id"])
  end

  # Four metrics, each compared independently of the other three (AI-1427) -- a config change
  # that trades cost for accuracy should show as "cost worse, accuracy better", not wash out into
  # a single composite score. higher_is_better flips the win direction for the two rate metrics
  # against the two cost/latency metrics, since "better" means opposite things for each pair.
  def evaluation_run_comparison_rows(run_a, run_b)
    label_a = "Run ##{run_a.resource_id}"
    label_b = "Run ##{run_b.resource_id}"

    [
      evaluation_run_comparison_row("Top 1 accuracy", run_a.top1_rate, run_b.top1_rate, label_a, label_b, value_format: :rate, higher_is_better: true),
      evaluation_run_comparison_row("Top 5 accuracy", run_a.top5_rate, run_b.top5_rate, label_a, label_b, value_format: :rate, higher_is_better: true),
      evaluation_run_comparison_row("Total cost", run_a.total_cost_usd&.to_f, run_b.total_cost_usd&.to_f, label_a, label_b, value_format: :cost, higher_is_better: false),
      evaluation_run_comparison_row("Average latency", run_a.average_latency_seconds, run_b.average_latency_seconds, label_a, label_b, value_format: :seconds, higher_is_better: false),
    ]
  end

private

  def evaluation_run_elapsed(run)
    return nil if run.started_at.blank?

    Time.current - Time.zone.parse(run.started_at.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def evaluation_run_comparison_row(label, value_a, value_b, label_a, label_b, value_format:, higher_is_better:)
    {
      label:,
      value_a: evaluation_run_comparison_value(value_a, value_format),
      value_b: evaluation_run_comparison_value(value_b, value_format),
      better: evaluation_run_comparison_winner(value_a, value_b, label_a, label_b, higher_is_better),
    }
  end

  def evaluation_run_comparison_value(value, value_format)
    case value_format
    when :rate then evaluation_run_rate(value)
    when :seconds then evaluation_run_seconds(value)
    when :cost then value.nil? ? "-" : sprintf("$%.4f", value)
    end
  end

  # Named by the run's own id (label_a/label_b, e.g. "Run #9"), not an arbitrary "Run A"/"Run B" --
  # an operator comparing more than one pair over a session shouldn't have to remember which
  # letter was which run. nil on either side means one run has no data for this metric at all
  # (e.g. a run with 0 results) -- that's reported as "Not available", distinct from "No change",
  # since the two runs being equal is a different fact to the metric being unmeasurable (AI-1427
  # review feedback).
  def evaluation_run_comparison_winner(value_a, value_b, label_a, label_b, higher_is_better)
    return "Not available" if value_a.nil? || value_b.nil?
    return "No change" if value_a == value_b

    a_wins = higher_is_better ? value_a > value_b : value_a < value_b
    a_wins ? label_a : label_b
  end
end
