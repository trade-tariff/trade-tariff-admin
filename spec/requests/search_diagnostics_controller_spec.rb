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
                timestamp: "2026-06-05 09:59:00.000",
                event: "search_completed",
                search_type: "classic",
                fields: {
                  request_id: "request-123",
                  query: "horse",
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
                timestamp: "2026-06-05 09:59:05.000",
                event: "retrieval_results_returned",
                search_type: "interactive",
                fields: {
                  request_id: "request-123",
                  search_type: "interactive",
                  query: "red leather shoes",
                  retrieval_method: "hybrid",
                  stage: "after_rrf",
                  leg: nil,
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
            ],
          },
        )
    end

    let(:make_request) { get search_diagnostic_path("request-123") }

    it { is_expected.to have_http_status :success }

    it "renders the diagnostics journey shell" do
      rendered_page

      expect(response.body).to include("request-123", "platform-logs-test", "Search journey events", "search_completed", "classic", "horse")
    end

    it "renders classic exact and fuzzy event summaries" do
      rendered_page

      expect(response.body).to include("Exact match - search reference - horse - commodities/0101210000", "Fuzzy results returned - 1 result", "6403990000", "14.2")
    end

    it "renders internal interactive event summaries" do
      rendered_page

      expect(response.body).to include("Interactive configuration used", "Retrieval method", "hybrid", "Rrf k", "60", "Questions returned - 1 question", "What material are the shoes made from?", "Hybrid - After rrf - 1 result", "12.7", "View self-text", "View labels")
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
end
