RSpec.describe SearchAnalyticsController do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:analytics) do
    SearchAnalytics.new(
      period: "24h",
      view: "all",
      generated_at: "2026-06-10T09:55:00Z",
      data_through: "2026-06-10T09:50:00Z",
      summary: {
        searches: 1_240,
        failure_rate: 0.012,
        zero_result_rate: 0.084,
        selection_rate: 0.41,
        p90_latency_ms: 1_800,
      },
      summary_statuses: {
        failure_rate: { level: "good", message: "Failures are low" },
      },
      trends: {
        volume: [
          { bucket: "2026-06-10T09:00:00Z", all: 52, classic: 31, internal: 21 },
        ],
        outcomes: [
          { bucket: "2026-06-10T09:00:00Z", completed: 50, failed: 2, zero_result: 4, selected: 19 },
        ],
      },
      comparisons: {
        classic: { searches: 710, zero_result_rate: 0.07, selection_rate: 0.43, p90_latency_ms: 620 },
      },
      improvement_terms: [
        { query: "trainers", searches: 40, zero_results: 18, selection_rate: 0.12 },
      ],
    )
  end

  before do
    allow(SearchAnalytics).to receive(:fetch).and_return(analytics)
  end

  describe "GET #index" do
    let(:make_request) { get search_analytics_path }

    it { is_expected.to have_http_status :success }

    it "fetches the default dashboard" do
      rendered_page

      expect(SearchAnalytics).to have_received(:fetch).with(period: "24h", view: "all")
    end

    it "renders filters and the five top metrics" do
      rendered_page

      expect_dashboard_content
    end

    context "with filters" do
      let(:make_request) { get search_analytics_path, params: { period: "7d", view: "classic" } }

      it "passes period and view through" do
        rendered_page

        expect(SearchAnalytics).to have_received(:fetch).with(period: "7d", view: "classic")
      end
    end

    context "when analytics are not available yet" do
      before do
        allow(SearchAnalytics).to receive(:fetch).and_raise(Faraday::ResourceNotFound.new("missing snapshots"))
      end

      it "renders the dashboard instead of redirecting back to itself" do
        expect(rendered_page).to have_http_status(:success)
      end

      it "shows that analytics are unavailable" do
        rendered_page

        expect(response.body).to include("Search analytics are not available yet.")
      end
    end

    context "when unauthorised" do
      let(:current_user) { create(:user, :guest) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  def expect_dashboard_content
    expect(response.body).to include("24 hours", "7 days", "30 days", "All", "Classic", "Internal")
    expect(response.body).not_to include("Suggestions")
    expect(response.body).to include("Searches", "1,240")
    expect(response.body).to include("Failure rate", "1.2%")
    expect(response.body).to include("Zero-result rate", "8.4%")
    expect(response.body).to include("Selection rate", "41%")
    expect(response.body).to include("P90 latency", "1.8s")
    expect(response.body).to include("Generated 10 June 2026 at 09:55")
    expect(response.body).not_to include("Query window ended")
    expect(response.body).to include("Zero search terms")
  end
end
