# One execution of an experiment. Unlike every other model in this app, a run is never edited by the
# admin app after creation (only the eval app updates its status), so it has no generic #save/#update
# path — only .launch!, which needs a one-off Idempotency-Key header the shared ApiEntity#save/#update
# machinery has no way to send.
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
      api.post(collection_path, payload, { "Idempotency-Key" => idempotency_key })
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

  # Override fields are named dynamically from the backend's own schema (OverrideSchema; see
  # EvaluationConfiguration) rather than being declared as EvaluationRun attributes. The launch
  # form always starts from a blank, unpersisted run, so the correct starting value for every
  # override field is simply "unset" — but the form builder (e.g. govuk_select) still calls
  # object.public_send(field_name) to read that starting value, and ApiEntity#method_missing
  # raises for any name it was never assigned. Returning nil here instead keeps every override
  # field blank on a fresh form, which is what "Use default" already means for all of them.
  def method_missing(method_name, *args, &block)
    return super if method_name.to_s.end_with?("=") || args.any? || block

    attributes.key?(method_name) ? self[method_name] : nil
  end

  def respond_to_missing?(method_name, include_private = false)
    !method_name.to_s.end_with?("=") || super
  end
end
