RSpec.describe SearchAnalyticsController do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:analytics) do
    SearchAnalytics.new(
      period: "24h",
      view: "all",
      availability: { journey_metrics: true, costs_match_view: true },
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

    context "with the UK internal view" do
      let(:make_request) { get search_analytics_path, params: { period: "custom", view: "internal", from: "2026-09-20", to: "2026-09-23" } }

      before { allow(TradeTariffAdmin::ServiceChooser).to receive(:uk?).and_return(true) }

      it "uses one date pair for the dashboard and workbook" do
        rendered_page
        expect_shared_workbook_form
      end

      it "allows the shared date fields through today" do
        rendered_page
        page = Nokogiri::HTML(response.body)

        expect(page.css("#from, #to").map { |input| input["max"] }).to eq([Time.current.utc.to_date.iso8601] * 2)
      end
    end

    context "with the XI internal view" do
      let(:make_request) { get search_analytics_path, params: { view: "internal" } }

      before { allow(TradeTariffAdmin::ServiceChooser).to receive(:uk?).and_return(false) }

      it "does not offer the workbook" do
        expect(rendered_page.body).not_to include("Download classifier workbook")
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

        expect(response.body).to include("No collected search analytics are available for the selected dates.")
      end
    end

    context "when unauthorised" do
      let(:current_user) { create(:user, :guest) }

      it { is_expected.to have_http_status :forbidden }
    end

    it "explains search-start counts without guided events" do
      rendered_page

      expect_search_start_explanation(guided_events: false)
    end

    %w[all internal].each do |analytics_view|
      context "with guided events on the #{analytics_view} view" do
        let(:make_request) { get search_analytics_path, params: { view: analytics_view } }

        before { analytics.assign_attributes(frontend_events: guided_frontend_events) }

        it "explains guided counts separately from search requests" do
          rendered_page

          expect_guided_count_explanations
        end
      end
    end

    context "with classic view and guided event data" do
      let(:make_request) { get search_analytics_path, params: { view: "classic" } }

      before { analytics.assign_attributes(frontend_events: guided_frontend_events) }

      it "keeps guided-event explanations off the classic view" do
        rendered_page

        expect_search_start_explanation(guided_events: false)
      end
    end

    context "when coverage is incomplete" do
      let(:make_request) { get search_analytics_path, params: { view: "internal" } }

      before do
        analytics.assign_attributes(
          coverage: { complete: false, collected_days: 30, expected_days: 30 },
          availability: {
            journey_metrics: true,
            costs_match_view: true,
            journey_outcomes: true,
            journey_outcome_coverage: { complete: false },
          },
          frontend_events: guided_frontend_events(complete: false),
        )
      end

      it "explains that charts can cover different days" do
        rendered_page

        expect_partial_coverage_explanation
      end
    end
  end

  def expect_search_start_explanation(guided_events:)
    aggregate_failures do
      expect(response.body).to include("Search requests count searches with a recorded start")
      expect(response.body).to include("Several questions in one search count once.")
      expect(response.body).to include("One search can appear in more than one time period")
      expect(response.body).to include("Selected and Zero result can overlap the other lines")
      expect(response.body).to include("Question only does not show that the user left")
      if guided_events
        expect(response.body).to include("Observed journeys count searches with a recorded guided page or click")
        expect(response.body).to include("These totals can differ.")
      else
        expect(response.body).not_to include("Observed journeys count searches")
        expect(response.body).not_to include("commodity result clicks")
      end
    end
  end

  def expect_guided_count_explanations
    expect_search_start_explanation(guided_events: true)
    expect_guided_event_units
  end

  def expect_guided_event_units
    aggregate_failures do
      expect(response.body).to include("commodity result clicks, not answers to offered questions")
      expect(response.body).to include("Page events count pages, not searches.")
      expect(response.body).to include("A browser session is not a search or a person.")
      expect(response.body).to include("These rows count commodity result clicks, not searches.")
      expect(response.body).to include("Each observed journey appears once, using its highest reported question count.")
    end
  end

  def expect_partial_coverage_explanation
    aggregate_failures do
      expect(response.body).to include("30 of 30 UTC days have stored results")
      expect(response.body).to include("Charts can cover different days.")
      expect(response.body).to include("Missing days are not zero-traffic days")
      expect(response.body).to include("missing days are not zero-activity days")
      expect(response.body).to include("Missing days are not zero-outcome days")
    end
  end

  def guided_frontend_events(complete: true)
    {
      available: true,
      observed_journeys: 4,
      observed_sessions: 2,
      coverage: { supported: true, complete: complete },
      outcomes: [{ outcome: "question", rendered_events: 3, average_navigation_ms: 1_500 }],
      actions: { result_selected: 3, dont_know: 1 },
      selections: [{ result_rank: 1, confidence: "strong", event_count: 3 }],
      question_counts: [{ questions: 1, journeys: 4 }],
    }
  end

  def expect_shared_workbook_form
    page = Nokogiri::HTML(response.body)
    expect(page.css("input[type=date]").map { |input| input["value"] }).to eq(%w[2026-09-20 2026-09-23])
    button = page.at_css("button[formaction='#{search_export_workbooks_path(preset: 'custom')}']")
    expect(button["formmethod"]).to eq("post")
    expect(button["name"]).to eq("authenticity_token")
    expect(button["value"]).to be_present
    expect(button.ancestors("form").first.css("input[type=date]").size).to eq(2)
    expect(page.text).not_to include("Classifier workbook dates", "Starts with the dashboard dates")
  end

  def expect_dashboard_content
    expect(response.body).to include("24 hours", "7 days", "30 days", "All", "Classic", "Internal")
    expect(response.body).not_to include("Suggestions")
    expect(response.body).to include("Search requests", "1,240")
    expect(response.body).to include("Failure rate", "1.2%")
    expect(response.body).to include("Zero-result rate", "8.4%")
    expect(response.body).to include("Selection rate", "41%")
    expect(response.body).to include("P90 latency", "1.8s")
    expect(response.body).not_to include("Query window ended")
    expect(response.body).to include("Zero search terms")
  end
end
