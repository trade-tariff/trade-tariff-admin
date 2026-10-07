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
             :gold_query_set_id,
             :effective_configuration,
             :run_time_overrides,
             :result_count,
             :error_count,
             :gold_in_top1_count,
             :gold_in_top5_count,
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
    rate_of(gold_in_top1_count)
  end

  def top5_rate
    rate_of(gold_in_top5_count)
  end

  def average_latency_seconds
    return nil if result_count.to_i.zero?

    total_latency_seconds.to_f / result_count
  end

  # Override fields are named dynamically from the backend's own schema (OverrideSchema; see
  # EvaluationConfiguration) rather than being declared as EvaluationRun attributes. The launch
  # form always starts from a blank, unpersisted run, so the correct starting value for every
  # override field is simply "unset" — but the form builder (e.g. govuk_select) still calls
  # object.public_send(field_name) to read that starting value, and ApiEntity#method_missing
  # raises for any name it was never assigned. Returning nil here instead keeps every override
  # field blank on a fresh form, which is what "Use default" already means for all of them.
  # rubocop:disable Style/MissingRespondToMissing -- a broad respond_to_missing? here (e.g.
  # "anything not ending in =") would make @run.respond_to?(:policy_class) true, and Pundit's
  # PolicyFinder specifically probes that to decide how to resolve a policy class — it would then
  # call policy_class (routed back through this method_missing, returning nil) instead of its
  # normal "EvaluationRun" + "Policy" inference, breaking `authorize @run, ...` everywhere.
  # Confirmed by reproduction: Pundit::NotDefinedError, "unable to find policy `` for ...".
  # Leaving respond_to_missing? at ApiEntity's own definition (attributes.key?(name) || super) is
  # correct: nothing in this form's render path checks respond_to? before calling these dynamic
  # getters, so method_missing alone is enough to keep every override field blank.
  def method_missing(method_name, *args, &block)
    return super if method_name.to_s.end_with?("=") || args.any? || block

    attributes.key?(method_name) ? self[method_name] : nil
  end
  # rubocop:enable Style/MissingRespondToMissing

private

  def rate_of(count)
    return nil if result_count.to_i.zero?

    (count.to_f / result_count) * 100
  end
end
