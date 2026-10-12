# One gold query's outcome within a run. The backend's own route for this is flat
# (admin/search/evaluation/results?run_id=...), not nested under the run the way gold query set items
# are nested under their set — only this admin app's own routes nest it, for a readable URL.
class EvaluationResult
  include ApiEntity

  uk_only

  set_collection_path "admin/search/evaluation/results"
  set_singular_path "admin/search/evaluation/results/:id"

  attributes :run_id,
             :source_type,
             :source_id,
             :persona,
             :expected_code,
             :final_code,
             :final_rank,
             :gold_in_top1,
             :gold_in_top5,
             :latency_seconds,
             :cost_usd,
             :provider_calls,
             :pricing_known,
             :error,
             :trace

  def passed?
    gold_in_top5 == true
  end

  # A clean three-way split with no overlap: an errored result's gold_in_top5 is always false
  # too (the eval app posts gold_in_top1/gold_in_top5 as false whenever a gold query's own
  # session raises), so checking error first is enough to tell a session error apart from a
  # genuine wrong-answer miss, which passed? alone can't do (AI-1432).
  def outcome
    return "pass" if passed?
    return "error" if error.present?

    "fail"
  end

  # trace defaults to {} on the backend (never nil), and a result created before this slice's eval-app
  # change (Task 3) has no question_trace key inside it at all — both cases should read as "no rounds
  # recorded", not raise or show nil.
  def question_trace
    Array(trace&.dig("question_trace"))
  end
end
