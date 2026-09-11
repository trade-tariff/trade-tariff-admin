RSpec.describe "Search diagnostics errors", :aggregate_failures do
  include_context "with authenticated user"

  let(:failure_fields) do
    {
      operation: "opensearch_retrieval",
      failure_code: "opensearch_failed",
      error_type: "OpenSearch::Transport::Transport::Errors::Unauthorized",
      error_message: "[401] Unauthorized",
      search_degraded: true,
      opensearch_failed: true,
    }
  end
  let(:events) do
    [
      { event: "search_stage_failed", timestamp: "2026-09-11 09:00:42.392", fields: failure_fields },
      { event: "search_completed", timestamp: "2026-09-11 09:00:56.540", fields: { result_count: 5, results_type: "hybrid", search_degraded: true, opensearch_failed: true } },
    ]
  end
  let(:page) { Capybara.string(response.body) }

  before do
    stub_api_request("/search_diagnostics/request-errors")
      .to_return jsonapi_response(:search_diagnostic, { resource_id: "request-errors", request_id: "request-errors", events: events })

    get search_diagnostic_path("request-errors")
  end

  it "shows the cause without opening disclosures" do
    expect(response).to have_http_status(:success)
    expect(page).to have_css("#search-diagnostics-errors h2", text: "Search completed with errors")
    expect(page).to have_css("#search-diagnostics-errors", text: "opensearch_retrieval")
    expect(page).to have_css("#search-diagnostics-errors", text: "[401] Unauthorized")
    expect(page).to have_css("#search-diagnostics-errors", text: failure_fields[:error_type])
  end

  it "distinguishes returned results from a healthy search" do
    expect(page).to have_css(".govuk-tag", text: "Completed with errors")
    expect(page).to have_css(".govuk-tag", text: "Results returned")
    expect(page).to have_css("td[data-label='Summary']", text: "[401] Unauthorized")
    expect(page).to have_css("td[data-label='Summary']", text: "Search completed with errors - hybrid")
  end

  it "links each failure to its event" do
    link = page.find("#search-diagnostics-errors a", match: :first)

    expect(page).to have_css("tr#{link[:href]}")
  end

  context "with a complete failure" do
    let(:events) { [{ event: "search_failed", fields: { error_type: "Faraday::TimeoutError", error_message: "Timed out" } }] }

    it "distinguishes a failed search from degraded results" do
      expect(page).to have_css("#search-diagnostics-errors h2", text: "Search failed", exact_text: true)
      expect(page).to have_css(".govuk-tag", text: "Failed", exact_text: true)
      expect(page).not_to have_css(".govuk-tag", text: "Results returned")
    end
  end

  context "with an unknown event carrying an error" do
    let(:events) { [{ event: "new_provider_event", fields: { error_message: "Provider unavailable" } }] }

    it "surfaces the error without an event-specific mapping" do
      expect(page).to have_css("#search-diagnostics-errors", text: "Provider unavailable")
      expect(page).to have_css("td[data-label='Summary']", text: "Provider unavailable")
    end
  end

  context "with an error on a specially rendered event" do
    let(:events) { [{ event: "answer_returned", fields: { error_type: "InvalidAnswer", error_message: "Invalid code" } }] }

    it "does not hide errors behind specialised rendering" do
      expect(page).to have_css("#search-diagnostics-errors", text: "InvalidAnswer")
      expect(page).to have_css("td[data-label='Summary']", text: "Invalid code")
    end
  end

  context "with only propagated failure flags" do
    let(:events) { [{ event: "search_completed", fields: { search_degraded: "true", embedding_generation_failed: "true", result_count: 2 } }] }

    it "shows degradation even without the original failure event" do
      expect(page).to have_css("#search-diagnostics-errors", text: "embedding_generation_failed")
      expect(page).to have_css(".govuk-tag", text: "Completed with errors")
    end
  end

  context "with a recovered error and a clean completion event" do
    let(:events) do
      [
        { event: "api_call_completed", fields: { error_message: "Rate limited" } },
        { event: "search_completed", fields: { result_count: 5 } },
      ]
    end

    it "keeps the earlier error visible after recovery" do
      expect(page).to have_css("#search-diagnostics-errors", text: "Rate limited")
      expect(page).to have_css(".govuk-tag", text: "Completed with errors")
      expect(page).to have_css("td[data-label='Summary']", text: "Search completed with errors")
    end
  end

  context "with untrusted, truncated error text" do
    let(:failure_fields) { super().merge(error_message: "<script>alert('error')</script> [REDACTED]", error_message_truncated: "true") }

    it "escapes the message and retains redaction and truncation information" do
      expect(page).not_to have_css("script", text: "alert('error')", visible: :all)
      expect(page).to have_css("#search-diagnostics-errors", text: "<script>alert('error')</script> [REDACTED]")
      expect(page).to have_css("#search-diagnostics-errors", text: "message truncated")
    end
  end

  context "with an embedding exception class" do
    let(:events) { [{ event: "embedding_api_call_failed", fields: { error_class: "Faraday::TimeoutError", error_message: "Timed out" } }] }

    it "shows the exception class outside raw fields" do
      expect(page).to have_css("#search-diagnostics-errors", text: "Faraday::TimeoutError")
      expect(page).to have_css("td[data-label='Summary']", text: "Faraday::TimeoutError")
      expect(page).to have_css("dl", text: "Error classFaraday::TimeoutError", visible: :all)
    end
  end

  ["{}", "[]", '{"Error":"MixedCase"}'].each do |message|
    context "with JSON-shaped error text #{message}" do
      let(:events) { [{ event: "api_call_completed", fields: { error_message: message } }] }

      it "preserves the literal message and flags the error" do
        expect(page).to have_css("#search-diagnostics-errors", text: "Api call completed - #{message}")
        expect(page).to have_css("td[data-label='Summary']", text: "Api call completed - #{message}")
      end
    end
  end

  context "with disabled configuration switches" do
    let(:events) { [{ event: "interactive_configuration_used", fields: { details: { search_labels_enabled: false } } }] }

    it "shows disabled values rather than hiding them" do
      expect(page).to have_css("dl", text: "Search labels enabledfalse", visible: :all)
      expect(page).not_to have_css("#search-diagnostics-errors")
    end
  end

  [false, "false"].each do |flag|
    context "with false intercept flags #{flag.inspect}" do
      let(:events) do
        [{ event: "search_completed", fields: { description_intercept_matched: true, description_intercept_term: "fish", description_intercept_excluded: flag, description_intercept_filtering: flag } }]
      end

      it "does not report exclusion or filtering" do
        expect(page).to have_css("dl", text: "Description interceptMatched fish", visible: :all)
        expect(page).not_to have_css("dl", text: "Matched fish excluded", visible: :all)
        expect(page).not_to have_css("dl", text: "Matched fish filtering", visible: :all)
      end
    end
  end

  context "with an error on the completion event" do
    let(:events) { [{ event: "search_completed", fields: { error_message: "Provider unavailable", result_count: 0 } }] }

    it "keeps the completion error visible" do
      expect(page).to have_css("#search-diagnostics-errors", text: "Provider unavailable")
      expect(page).to have_css("td[data-label='Summary']", text: "Search completed with errors - Provider unavailable")
    end
  end

  context "with only an error status" do
    let(:events) { [{ event: "retrieval_leg_completed", fields: { status: "error" } }] }

    it "identifies the error in the event summary" do
      expect(page).to have_css("td[data-label='Summary']", text: "Retrieval leg completed - error")
    end
  end

  context "with a successful search" do
    let(:events) do
      [{ event: "search_completed", fields: { result_count: 5, search_degraded: "false", opensearch_failed: "false", error_message: "", error_type: nil } }]
    end

    it "does not flag false or empty error fields" do
      expect(page).not_to have_css("#search-diagnostics-errors")
      expect(page).not_to have_css(".govuk-tag", text: "Completed with errors")
      expect(page).to have_css(".govuk-tag", text: "Results returned")
    end
  end
end
