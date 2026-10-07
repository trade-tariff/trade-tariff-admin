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
  # row showing its own latency too would be more noise than signal.
  def evaluation_run_outlier_link(run, outlier, value_field)
    result = run.public_send(outlier)
    return "-" if result.nil?

    label = "#{result['source_id']} (#{value_field == 'cost_usd' ? '$' : ''}#{result[value_field]}#{value_field == 'latency_seconds' ? 's' : ''})"
    link_to label, evaluation_run_result_path(run, result["id"])
  end

private

  def evaluation_run_elapsed(run)
    return nil if run.started_at.blank?

    Time.current - Time.zone.parse(run.started_at.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
