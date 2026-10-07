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

private

  def evaluation_run_elapsed(run)
    return nil if run.started_at.blank?

    Time.current - Time.zone.parse(run.started_at.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
