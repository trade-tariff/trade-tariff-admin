RSpec.describe SearchDiagnosticsController do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  describe "GET #index" do
    let(:make_request) { get search_diagnostics_path }

    it { is_expected.to have_http_status :success }

    it "renders the search form" do
      rendered_page

      expect(response.body).to include("Search diagnostics", "Request ID", "Find diagnostics")
    end

    context "when a request id is submitted" do
      let(:make_request) { get search_diagnostics_path, params: { request_id: " request-123 " } }

      it { is_expected.to redirect_to(search_diagnostic_path("request-123")) }
    end

    context "when unauthorised" do
      let(:current_user) { create(:user, :guest) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "GET #show" do
    before do
      stub_api_request("/search_diagnostics/request-123")
        .to_return jsonapi_response(
          :search_diagnostic,
          {
            resource_id: "request-123",
            request_id: "request-123",
            log_group_name: "platform-logs-test",
            start_time: "2026-06-02T10:00:00Z",
            end_time: "2026-06-05T10:00:00Z",
            events: [
              {
                timestamp: "2026-06-05 09:58:58.000",
                event: "search_started",
                search_type: "interactive",
                fields: {
                  request_id: "request-123",
                  search_type: "interactive",
                  query: "red leather shoes",
                },
              },
              {
                timestamp: "2026-06-05 09:58:59.000",
                event: "description_intercept_checked",
                search_type: "interactive",
                fields: {
                  request_id: "request-123",
                  query: "red leather shoes",
                  matched: true,
                  term: "shoes",
                  excluded: false,
                  filtering: true,
                  filter_prefix_count: 1,
                  guidance_level: "info",
                  guidance_location: "results",
                  escalate_to_webchat: false,
                },
              },
              {
                timestamp: "2026-06-05 09:59:00.000",
                event: "search_completed",
                search_type: "classic",
                fields: {
                  request_id: "request-123",
                  query: "horse",
                  total_duration_ms: 85.4,
                },
              },
              {
                timestamp: "2026-06-05 09:59:01.000",
                event: "exact_match_selected",
                search_type: "classic",
                fields: {
                  request_id: "request-123",
                  search_type: "classic",
                  query: "horse",
                  match_source: "search_reference",
                  matched_value: "horse",
                  target_id: "0101210000",
                  goods_nomenclature_item_id: "0101210000",
                  goods_nomenclature_sid: 123,
                  goods_nomenclature_class: "Commodity",
                  details: {
                    goods_nomenclature_item_id: "0101210000",
                    goods_nomenclature_sid: 123,
                    goods_nomenclature_class: "Commodity",
                    self_text_id: 123,
                  },
                },
              },
              {
                timestamp: "2026-06-05 09:59:02.000",
                event: "fuzzy_results_returned",
                search_type: "classic",
                fields: {
                  request_id: "request-123",
                  search_type: "classic",
                  query: "shoe",
                  result_count: 1,
                  details: {
                    goods_nomenclature_match: {
                      commodities: [
                        {
                          goods_nomenclature_item_id: "6403990000",
                          goods_nomenclature_sid: 456,
                          goods_nomenclature_class: "Commodity",
                          score: 14.2,
                        },
                      ],
                    },
                  },
                },
              },
              {
                timestamp: "2026-06-05 09:59:03.000",
                event: "interactive_configuration_used",
                search_type: "interactive",
                fields: {
                  request_id: "request-123",
                  search_type: "interactive",
                  query: "red leather shoes",
                  details: {
                    retrieval_method: "hybrid",
                    rrf_k: 60,
                    filter_prefixes: %w[64],
                  },
                },
              },
              {
                timestamp: "2026-06-05 09:59:03.500",
                event: "query_expansion_decided",
                search_type: "interactive",
                fields: {
                  request_id: "request-123",
                  query: "red leather shoes",
                  expand: true,
                  reason: "low_results",
                  result_count: 2,
                  max_score: 4.5,
                },
              },
              {
                timestamp: "2026-06-05 09:59:03.750",
                event: "query_expanded",
                search_type: "interactive",
                fields: {
                  request_id: "request-123",
                  original_query: "red leather shoes",
                  expanded_query: "red leather footwear",
                  reason: "colloquial",
                  duration_ms: 120.25,
                },
              },
              {
                timestamp: "2026-06-05 09:59:03.900",
                event: "query_refined",
                search_type: "interactive",
                fields: {
                  request_id: "request-123",
                  base_query: "red leather footwear",
                  original_query: "red leather footwear",
                  refined_query: "red leather footwear womens",
                  effective_query: "red leather footwear womens",
                  answer_count: 1,
                  added_answers: %w[womens],
                  iteration: 2,
                },
              },
              {
                timestamp: "2026-06-05 09:59:03.950",
                event: "note_evidence_evaluated",
                search_type: "interactive",
                fields: {
                  request_id: "request-123",
                  query: "pig iron",
                  effective_query: "pig iron primary forms",
                  iteration: 2,
                  attempt_number: 2,
                  operation: "interactive_search",
                  note_evidence_enabled: true,
                  note_evidence_status: "selected",
                  considered_note_count: 4,
                  considered_evidence_count: 5,
                  considered_association_count: 5,
                  considered_distinct_source_count: 3,
                  selected_note_count: 1,
                  selected_evidence_count: 2,
                  selected_distinct_source_count: 2,
                  omitted_evidence_count: 1,
                  logged_omitted_evidence_count: 1,
                  omitted_evidence_truncated: false,
                  details: {
                    limits: { minimum_score: 6, per_note: 2, total: 8 },
                    selected_contexts: [
                      {
                        context_hash: "chapter-72-hash",
                        note_ref: "compressed_note_1",
                        commodity_codes: %w[7201101100 7201200000],
                        evidence: [
                          {
                            evidence_kind: "note_block",
                            source_node_key: "note_block:customs_tariff_chapter_note:1.31:72:1:a",
                            source: "pig Iron",
                            source_ref: "chapter 72 note",
                            source_type: "customs_tariff_chapter_note",
                            source_id: "72",
                            source_version: "1.31",
                            type: "definition",
                            fragment_node_keys: ["note_fragment:customs_tariff_chapter_note:1.31:72:0001"],
                            fragment_node_keys_truncated: false,
                            graph_paths: [%w[contains contains applies_to]],
                            text: "Pig iron means iron-carbon alloys containing more than 2% carbon.",
                            score: 35,
                            score_reasons: ["exact term match pig iron", "definition block"],
                            decision: "selected",
                          },
                          {
                            evidence_kind: "note_fragment",
                            source_node_key: "note_fragment:customs_tariff_chapter_note:1.31:72:0042",
                            source: "Chapter 72 note fragment 42",
                            source_ref: "chapter 72 note",
                            source_type: "customs_tariff_chapter_note",
                            source_id: "72",
                            source_version: "1.31",
                            parent_source_node_key: "note_source:customs_tariff_chapter_note:1.31:72",
                            parent_source_title: "Chapter 72 notes",
                            type: "inclusion",
                            range_node_key: "range:heading:7201",
                            range_type: "heading",
                            range_code: "7201",
                            graph_paths: [%w[contains references expands_to]],
                            text: "Heading 7201 includes pig iron and spiegeleisen.",
                            score: 16,
                            score_reasons: ["candidate heading 7201"],
                            decision: "selected",
                          },
                        ],
                      },
                    ],
                    omitted_evidence: [
                      {
                        context_hash: "chapter-02-hash",
                        evidence_kind: "note_fragment",
                        source_node_key: "note_fragment:customs_tariff_chapter_note:1.31:02:0001",
                        source_ref: "chapter 2 note",
                        text: "Unrelated meat note.",
                        score: 3,
                        decision: "omitted",
                        omission_reason: "below_minimum_score",
                      },
                    ],
                  },
                },
              },
              {
                timestamp: "2026-06-05 09:59:04.000",
                event: "question_returned",
                search_type: "interactive",
                fields: {
                  request_id: "request-123",
                  question_count: 1,
                  details: {
                    questions: [
                      { question: "What material are the shoes made from?" },
                    ],
                  },
                },
              },
              {
                timestamp: "2026-06-05 09:59:04.500",
                event: "api_call_completed",
                search_type: "interactive",
                fields: {
                  request_id: "request-123",
                  model: "gpt-4.1-mini",
                  response_type: "questions",
                  attempt_number: 1,
                  duration_ms: 450.1,
                  provider: "openai",
                  event_kind: "interactive_search",
                  input_tokens: 1_000,
                  output_tokens: 200,
                  total_tokens: 1_200,
                  input_cost_usd: 0.002,
                  output_cost_usd: 0.0016,
                  total_cost_usd: 0.0036,
                  pricing_known: true,
                },
              },
              {
                timestamp: "2026-06-05 09:59:04.600",
                event: "api_call_completed",
                search_type: "interactive",
                fields: {
                  request_id: "request-123",
                  model: "gpt-4.1-mini",
                  response_type: "answers",
                  attempt_number: 2,
                  duration_ms: 320.0,
                  provider: "openai",
                  event_kind: "interactive_search_final_answer",
                  input_tokens: 500,
                  output_tokens: 100,
                  total_tokens: 600,
                  total_cost_usd: 0.0015,
                  pricing_known: true,
                },
              },
              {
                timestamp: "2026-06-05 09:59:04.700",
                event: "search_completed",
                search_type: "interactive",
                fields: {
                  request_id: "request-123",
                  query: "red leather shoes",
                  total_duration_ms: 1500.25,
                },
              },
              {
                timestamp: "2026-06-05 09:59:04.750",
                event: "retrieval_leg_completed",
                search_type: "interactive",
                fields: {
                  request_id: "request-123",
                  leg: "vector",
                  status: "success",
                  result_count: 1,
                  duration_ms: 50.4,
                },
              },
              {
                timestamp: "2026-06-05 09:59:05.000",
                event: "retrieval_results_returned",
                search_type: "interactive",
                fields: {
                  request_id: "request-123",
                  search_type: "interactive",
                  query: "red leather shoes",
                  effective_query: "red leather footwear womens",
                  retrieval_method: "hybrid",
                  stage: "after_rrf",
                  leg: nil,
                  iteration: 2,
                  result_count: 1,
                  details: {
                    results: [
                      {
                        goods_nomenclature_item_id: "6403990000",
                        goods_nomenclature_sid: 456,
                        goods_nomenclature_class: "Commodity",
                        score: 12.7,
                        self_text_id: 456,
                      },
                    ],
                  },
                },
              },
              {
                timestamp: "2026-06-05 09:59:06.000",
                event: "answer_returned",
                search_type: "interactive",
                fields: {
                  request_id: "request-123",
                  answer_count: 1,
                  confidence_levels: { strong: 1 },
                  attempt_number: 2,
                  details: {
                    answers: [
                      { commodity_code: "6403990000", confidence: "strong" },
                    ],
                  },
                },
              },
              {
                timestamp: "2026-06-05 09:59:07.000",
                event: "result_selected",
                search_type: nil,
                fields: {
                  request_id: "request-123",
                  goods_nomenclature_item_id: "6403990000",
                  goods_nomenclature_class: "Commodity",
                },
              },
              {
                timestamp: "2026-06-05 09:59:08.000",
                event: "search_failed",
                search_type: "interactive",
                fields: {
                  request_id: "request-123",
                  search_type: "interactive",
                  error_type: "Faraday::TimeoutError",
                  error_message: "connection timed out",
                  error_message_truncated: false,
                },
              },
            ],
          },
        )
    end

    let(:make_request) { get search_diagnostic_path("request-123") }

    it { is_expected.to have_http_status :success }

    it "renders the diagnostics journey shell" do
      rendered_page

      expect(response.body).to include("request-123", "platform-logs-test", "Search journey events", "Search completed", "Classic", "horse")
    end

    it "renders an operator overview in the summary list" do
      rendered_page

      expect(response.body).to include(*operator_overview_fragments)
    end

    it "renders classic exact and fuzzy event summaries" do
      rendered_page

      expect(response.body).to include("Exact match - search reference - horse - commodities/0101210000", "Fuzzy results returned - 1 result", "6403990000", "14.2")
    end

    it "renders internal interactive event summaries" do
      rendered_page

      expect(response.body).to include("Interactive configuration used", "Retrieval method", "hybrid", "Rrf k", "60", "Questions returned - 1 question", "What material are the shoes made from?", "Hybrid - After rrf - 1 result", "12.7", "View self-text", "View labels")
    end

    it "renders internal search iterations" do
      rendered_page

      expect(Capybara.string(response.body).text).to include(
        "Internal search iterations", "Iteration 2", "red leather footwear womens", "womens", "Hybrid after rrf - 1 result"
      )
    end

    it "renders compressed note evidence and omission reasons by iteration" do
      rendered_page

      page = Capybara.string(response.body)
      section = page.find("section.search-diagnostics-note-evidence")

      expect(section.text.squish).to include(*note_evidence_copy)
    end

    it "separates the journey and notes into GOV.UK tabs" do
      rendered_page
      page = Capybara.string(response.body)

      expect(page).to have_css(".govuk-tabs__list-item--selected a[href='#journey']", text: "Journey")
        .and have_css("a[href='#notes']", text: "Notes")
    end

    it "links journey evidence to the collapsed notes iteration" do
      rendered_page
      page = Capybara.string(response.body)

      expect(page).to have_css("#journey a[href='#notes']", text: "View iteration 2 notes")
        .and have_css("#notes details#note-evidence-iteration-2:not([open])")
    end

    it "keeps the note payload out of the journey panel" do
      rendered_page

      page = Capybara.string(response.body)
      payload = "Pig iron means iron-carbon alloys"

      expect([page.find("#journey").text.include?(payload), page.find("#notes").text.include?(payload)]).to eq([false, true])
    end

    it "renders the GOV.UK formatted log search window and event timeline chart" do
      rendered_page

      expect(response.body).to include("Log search window", "2 June 2026 at 10:00 to 5 June 2026 at 10:00", "Search event timeline", "Exact match selected", "Search failed")
    end

    it "links timeline markers to their matching event rows" do
      rendered_page

      page = Capybara.string(response.body)

      expect(page).to have_css(".search-diagnostics-timeline__marker-link[href='#search-event-0']", text: "09:58:58.000 Search started", normalize_ws: true)
        .and have_css("tr#search-event-0", text: "Search started")
    end

    it "renders query preparation, model, selection and failure events with readable copy" do
      rendered_page

      expect(response.body).to include(*readable_event_summaries)
    end

    it "shows the original search type for selected-result events with no logged type" do
      rendered_page

      selected_result_row = Capybara.string(response.body).find("tr", text: "Result selected")

      expect(selected_result_row).to have_css("td[data-label='Type']", text: "Internal")
    end

    context "when no events are found" do
      before do
        stub_api_request("/search_diagnostics/missing-request")
          .to_return jsonapi_response(
            :search_diagnostic,
            {
              resource_id: "missing-request",
              request_id: "missing-request",
              log_group_name: "platform-logs-test",
              start_time: "2026-06-02T10:00:00Z",
              end_time: "2026-06-05T10:00:00Z",
              events: [],
            },
          )
      end

      let(:make_request) { get search_diagnostic_path("missing-request") }

      it "renders an empty state" do
        rendered_page

        expect(response.body).to include("No search journey events were found for this request ID.")
      end
    end

    context "when the request predates compressed note evidence diagnostics" do
      before do
        stub_api_request("/search_diagnostics/legacy-request")
          .to_return jsonapi_response(
            :search_diagnostic,
            {
              resource_id: "legacy-request",
              request_id: "legacy-request",
              log_group_name: "platform-logs-test",
              start_time: "2026-06-02T10:00:00Z",
              end_time: "2026-06-05T10:00:00Z",
              events: [
                {
                  timestamp: "2026-06-05 09:58:58.000",
                  event: "search_started",
                  search_type: "interactive",
                  fields: { request_id: "legacy-request", query: "pig iron" },
                },
              ],
            },
          )
      end

      let(:make_request) { get search_diagnostic_path("legacy-request") }

      it "explains that no note evidence event was logged" do
        rendered_page

        expect(response.body).to include(
          "Compressed note evidence",
          "No compressed note evidence event was logged for this request. Older requests may pre-date this diagnostic.",
        )
      end
    end

    context "when note evidence is not selected" do
      before do
        events = %w[disabled no_compressed_notes no_eligible_evidence].map.with_index do |status, index|
          {
            timestamp: "2026-06-05 09:58:5#{index}.000",
            event: "note_evidence_evaluated",
            search_type: "interactive",
            fields: {
              request_id: "status-request",
              iteration: index + 1,
              note_evidence_status: status,
              omitted_evidence_count: status == "no_eligible_evidence" ? 3 : 0,
              details: {},
            },
          }
        end
        stub_api_request("/search_diagnostics/status-request")
          .to_return jsonapi_response(
            :search_diagnostic,
            {
              resource_id: "status-request",
              request_id: "status-request",
              log_group_name: "platform-logs-test",
              start_time: "2026-06-02T10:00:00Z",
              end_time: "2026-06-05T10:00:00Z",
              events:,
            },
          )
      end

      let(:make_request) { get search_diagnostic_path("status-request") }

      it "renders each empty selection state without inventing omitted samples" do
        rendered_page

        copy = ["Disabled", "No compressed notes", "No eligible evidence", "No omitted evidence samples were logged (3 omitted in total).", "Considered unavailable contexts; unavailable reported evidence records", "Selected unavailable contexts; unavailable reported evidence records", "No compressed note passage was added to this model prompt."]

        expect(Capybara.string(response.body).text.squish).to include(*copy)
      end
    end

    context "when the backend cannot load diagnostics" do
      before do
        stub_api_request("/search_diagnostics/request-123").to_return(status: 502, body: "", headers: {})
      end

      it { is_expected.to redirect_to(search_diagnostics_path) }

      it "shows a failure message" do
        rendered_page

        expect(flash[:alert]).to eq("Search diagnostics could not be loaded.")
      end
    end

    context "when unauthorised" do
      let(:current_user) { create(:user, :guest) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  def readable_event_summaries
    [
      "Search started - red leather shoes",
      "Description intercept matched - shoes",
      "Query expansion used - low results",
      "Query expanded - red leather shoes to red leather footwear",
      "Query refined - iteration 2 - added womens",
      "Model returned questions - attempt 1",
      "Hybrid - After rrf - 1 result - iteration 2 - query: red leather footwear womens",
      "Vector retrieval succeeded - 1 result",
      "Answers returned - 1 answer",
      "Result selected - commodity 6403990000",
      "Search failed - Faraday::TimeoutError",
    ]
  end

  def note_evidence_copy
    [
      "Compressed note evidence",
      "Selected",
      "Iteration 2",
      "attempt 2",
      "Interactive search",
      "Search query: pig iron",
      "pig iron primary forms",
      "4 contexts; 5 associations; 3 distinct source passages",
      "1 contexts; 2 distinct source passages",
      "compressed_note_1",
      "chapter-72-hash",
      "7201101100, 7201200000",
      "pig Iron",
      "chapter 72 note",
      "note_block:customs_tariff_chapter_note:1.31:72:1:a",
      "Source ID: 72",
      "Contained fragments: note_fragment:customs_tariff_chapter_note:1.31:72:0001",
      "Chapter 72 note fragment 42",
      "note_fragment:customs_tariff_chapter_note:1.31:72:0042",
      "Parent source: Chapter 72 notes (note_source:customs_tariff_chapter_note:1.31:72)",
      "Range: heading 7201 (range:heading:7201)",
      "Definition block",
      "Score 35",
      "exact term match pig iron",
      "contains → contains → applies_to",
      "Pig iron means iron-carbon alloys containing more than 2% carbon.",
      "Omitted evidence (1)",
      "below minimum score",
      "Unrelated meat note.",
    ]
  end

  def operator_overview_fragments
    [
      "Query",
      "red leather shoes",
      "govuk-tag govuk-tag--green",
      "Result selected",
      "Results returned",
      "govuk-tag govuk-tag--blue",
      "Internal",
      "Classic",
      "govuk-tag govuk-tag--orange",
      "Description intercept",
      "1 fuzzy result",
      "#{TradeTariffAdmin.frontend_host}/commodities/6403990000",
      "Elapsed time",
      "1.50 s",
      "Estimated AI cost",
      "$0.0051",
    ]
  end
end
