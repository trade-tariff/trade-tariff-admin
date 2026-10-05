# One execution of an experiment. Creation is the one mutation that doesn't go through the generic
# ApiEntity#save path — .launch! needs a one-off Idempotency-Key header that machinery has no way to
# send. Cancelling (#cancel!) is an ordinary attribute update, so it uses #update/#save as-is.
class EvaluationRun
  include ApiEntity

  uk_only

  set_collection_path "admin/search/evaluation/runs"
  set_singular_path "admin/search/evaluation/runs/:id"

  attributes :experiment_id,
             :status,
             :gold_query_set_id,
             :effective_configuration,
             :result_count,
             :error_count,
             :error_summary

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
end
