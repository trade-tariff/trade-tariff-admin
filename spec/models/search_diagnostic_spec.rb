RSpec.describe SearchDiagnostic do
  describe ".find" do
    before do
      stub_api_request("/search_diagnostics/request-123")
        .with(query: { lookback_hours: "24", limit: "50" })
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

    it "fetches diagnostics from the backend by request id" do
      diagnostic = described_class.find("request-123", lookback_hours: "24", limit: "50")
      event = diagnostic.events.first

      expect([diagnostic.request_id, diagnostic.log_group_name, event[:event], event.dig(:fields, :query)]).to eq(%w[request-123 platform-logs-test search_completed horse])
    end
  end

  describe "#events?" do
    it "is true when events are present" do
      diagnostic = described_class.new(events: [{ event: "search_started" }])

      expect(diagnostic).to be_events
    end

    it "is false when events are absent" do
      diagnostic = described_class.new(events: [])

      expect(diagnostic).not_to be_events
    end
  end
end
