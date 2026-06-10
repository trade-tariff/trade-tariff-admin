RSpec.describe SearchAnalytics do
  describe ".fetch" do
    subject(:analytics) { described_class.fetch(period: "24h", view: "all") }

    let(:expected_attributes) do
      {
        resource_id: "uk-24h-all",
        service: "uk",
        period: "24h",
        view: "all",
        bucket_size: "hour",
      }
    end

    before do
      stub_api_request("/search_analytics")
        .with(query: { period: "24h", view: "all" })
        .to_return jsonapi_response(
          :search_analytics,
          {
            resource_id: "uk-24h-all",
            service: "uk",
            period: "24h",
            view: "all",
            bucket_size: "hour",
            generated_at: "2026-06-10T09:55:00Z",
            data_through: "2026-06-10T09:50:00Z",
            summary: {
              searches: 1_240,
              failure_rate: 0.012,
            },
            trends: {
              volume: [
                { bucket: "2026-06-10T09:00:00Z", all: 52 },
              ],
            },
          },
        )
    end

    it "fetches the dashboard attributes from the backend" do
      expect(analytics).to have_attributes(expected_attributes)
    end

    it "parses the summary payload" do
      expect(analytics.summary[:searches]).to eq(1_240)
    end

    it "parses the trend payload" do
      expect(analytics.trends.dig(:volume, 0, :all)).to eq(52)
    end
  end
end
