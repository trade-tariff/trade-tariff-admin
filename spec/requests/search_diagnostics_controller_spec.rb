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
            ],
          },
        )
    end

    let(:make_request) { get search_diagnostic_path("request-123") }

    it { is_expected.to have_http_status :success }

    it "renders the diagnostics journey" do
      rendered_page

      expect(response.body).to include("request-123", "platform-logs-test", "Search journey events", "search_completed", "classic", "horse")
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
