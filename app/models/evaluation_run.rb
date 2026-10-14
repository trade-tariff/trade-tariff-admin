# One execution of an experiment. Creation is the one mutation that doesn't go through the generic
# ApiEntity#save path — .launch! needs a one-off Idempotency-Key header that machinery has no way to
# send. Cancelling (#cancel!) is an ordinary attribute update, so it uses #update/#save as-is.
class EvaluationRun
  include ApiEntity

  uk_only

  set_collection_path "admin/search/evaluation/runs"
  set_singular_path "admin/search/evaluation/runs/:id"

  # Matches the backend's own EvaluationRun::STATUSES exactly (app/models/evaluation_run.rb in
  # trade-tariff-backend) — duplicated here since this is a separate Rails process with no shared
  # constant, used for the run list's status filter.
  STATUSES = %w[queued running completed partially_failed failed cancelled].freeze

  attributes :experiment_id,
             :experiment_name,
             :status,
             :label,
             :gold_query_set_id,
             :intended_result_count,
             :effective_configuration,
             :run_time_overrides,
             :result_count,
             :error_count,
             :gold_in_top1_count,
             :gold_in_top5_count,
             :unpriced_result_count,
             :persona_breakdown,
             :max_cost_result,
             :min_cost_result,
             :max_latency_result,
             :min_latency_result,
             :error_summary,
             :triggered_by,
             :started_at,
             :completed_at,
             :total_cost_usd,
             :total_latency_seconds,
             :total_provider_calls,
             :created_at

  def self.launch!(experiment_id:, triggered_by:, run_time_overrides:, idempotency_key:)
    payload = {
      data: {
        type: :run,
        attributes: {
          experiment_id:,
          triggered_by:,
          configuration_overrides: run_time_overrides,
        },
      },
    }

    resp = begin
      api.post(collection_path, payload.to_json, { "Idempotency-Key" => idempotency_key, "Content-Type" => "application/json" })
    rescue Faraday::UnprocessableEntityError => e
      e.response
    end

    run = new(parse_jsonapi(resp) || {})
    run.send(:initialize_errors) if run[:errors]
    run
  end

  def generating?
    %w[queued running].include?(status)
  end

  def completed?
    status == "completed"
  end

  # True once this run has produced a result for every gold query it was ever going to attempt.
  # A "partially_failed" run can mean either of two very different things: every gold query got a
  # result, but one or more individual Q&A sessions errored along the way (this is still true),
  # or the run aborted partway through and the remaining gold queries were never attempted at all
  # (this is false, since result_count falls short of intended_result_count) -- the status string
  # alone can't tell the two apart (AI-1431). intended_result_count is a plain stored number, the
  # run's own gold query set size snapshotted once at launch (AI-1435) -- a run from before this
  # field existed has none, and nil never equals a real result_count, so it reads as false here,
  # not comparable, the same safe default as today.
  def fully_scored?
    result_count == intended_result_count
  end

  def cancellable?
    generating?
  end

  def finished_count
    result_count.to_i
  end

  def cancel!
    update(status: "cancelled")
  end

  # One row per key in effective_configuration, tagged with where that value actually came from — a
  # run-time override (set when this specific run was launched), an experiment default (carried every
  # time this experiment is launched, unless overridden), or the untouched baseline. Checked in that
  # order because a key can appear in more than one layer; the layer that actually won is the one
  # reported, and effective_configuration already holds exactly that value for every key, so there's
  # no need to separately know what the baseline's value was at the time this run was launched.
  def configuration_breakdown(experiment)
    run_overrides = run_time_overrides || {}
    experiment_overrides = experiment&.configuration_overrides || {}

    (effective_configuration || {}).map do |name, value|
      source = if run_overrides.key?(name)
                 "run"
               elsif experiment_overrides.key?(name)
                 "experiment"
               else
                 "baseline"
               end
      { name:, value:, source: }
    end
  end

  def top1_rate
    rate_of(gold_in_top1_count, result_count)
  end

  def top5_rate
    rate_of(gold_in_top5_count, result_count)
  end

  def average_latency_seconds
    average_of(total_latency_seconds, result_count)
  end

  # One row per persona present in persona_breakdown (the backend's own EvaluationRun#reconcile_aggregates!
  # groups by whatever persona string is actually on each result — see that method in
  # trade-tariff-backend — so there's no fixed list to iterate here either), each carrying the same
  # top1_rate/top5_rate/average_latency_seconds shape as the run's own totals above, just scoped to
  # that one persona's result_count instead of the whole run's — so the view can show which persona
  # is doing best or worst without repeating the rate/average maths per row. Sorted by persona name
  # for a stable display order, since persona_breakdown's own key order depends on which persona's
  # results happened to be grouped first.
  def persona_rows
    (persona_breakdown || {}).sort_by { |persona, _stats| persona }.map do |persona, stats|
      count = stats["result_count"].to_i
      {
        persona:,
        result_count: count,
        top1_rate: rate_of(stats["gold_in_top1_count"], count),
        top5_rate: rate_of(stats["gold_in_top5_count"], count),
        total_cost_usd: stats["total_cost_usd"],
        average_latency_seconds: average_of(stats["total_latency_seconds"], count),
      }
    end
  end

  # Override fields are named dynamically from the backend's own schema (OverrideSchema; see
  # EvaluationConfiguration) rather than being declared as EvaluationRun attributes. The launch
  # form always starts from a blank, unpersisted run, so the correct starting value for every
  # override field is simply "unset". The form builder (for example govuk_select) still calls
  # object.public_send(field_name) to read that starting value, and ApiEntity#method_missing
  # raises for any name it was never assigned. Returning nil here instead keeps every override
  # field blank on a fresh form, which is what "Use default" already means for all of them.
  #
  # Do not return true for arbitrary missing getters. A broad respond_to_missing? (for example
  # "anything not ending in =") makes respond_to?(:policy_class) true. Pundit's PolicyFinder
  # probes that name and, when it is true, calls policy_class instead of inferring
  # EvaluationRunPolicy. This method_missing returns nil for that call, and authorize then raises
  # Pundit::NotDefinedError ("unable to find policy ``"). Return false for :policy_class and
  # otherwise call super, so only names ApiEntity already advertises stay visible. The form does
  # not check respond_to? before public_send, so method_missing alone keeps unset override fields
  # blank.
  def method_missing(method_name, *args, &block)
    return super if method_name.to_s.end_with?("=") || args.any? || block

    attributes.key?(method_name) ? self[method_name] : nil
  end

  def respond_to_missing?(method_name, include_private = false)
    return false if method_name == :policy_class

    super
  end

private

  def rate_of(numerator, total)
    return nil if total.to_i.zero?

    (numerator.to_f / total) * 100
  end

  def average_of(total, count)
    return nil if count.to_i.zero?

    total.to_f / count
  end
end
