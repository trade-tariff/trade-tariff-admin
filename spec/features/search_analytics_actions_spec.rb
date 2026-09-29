RSpec.describe "Search activity breakdown" do
  include_context "with UK service"

  let(:counts) { { total: 100, navigation: 40, search: 50, unclassified: 10 } }
  let(:actions) do
    {
      available: true,
      coverage: { complete: true, collected_days: 1, expected_days: 1 },
      summary: counts,
      trend: [counts.merge(bucket: "2026-06-10T09:00:00Z")],
    }
  end

  %w[all classic internal].each do |view|
    it "shows the #{view} action split", :aggregate_failures do
      stub_actions(view:)
      visit search_analytics_path(view:)

      expect_action_summary("Total journeys" => "100", "Navigation" => "40", "Search" => "50", "Unclassified" => "10")
      expect_action_chart
    end
  end

  it "keeps existing rate values", :aggregate_failures do
    stub_actions
    visit search_analytics_path

    expect(page).to have_css("section[aria-label='Failure rate']", text: "1.2%")
    expect(page).to have_content("not clicks on its results")
    expect(page.text(:all)).to include("whether the user selects it or submits matching text", "including direct code lookups")
  end

  context "with partial action coverage" do
    let(:actions) do
      {
        available: true,
        coverage: { complete: false, collected_days: 1, expected_days: 2 },
        summary: counts.merge(total: 150, unclassified: 60),
        trend: [
          { bucket: "2026-06-09T00:00:00Z", total: 60, navigation: nil, search: nil, unclassified: 60 },
          counts.merge(bucket: "2026-06-10T00:00:00Z"),
        ],
      }
    end

    let(:expected_rows) do
      [
        ["9 June 2026", "60", "Unavailable", "Unavailable", "60"],
        ["10 June 2026", "100", "40", "50", "10"],
      ]
    end

    before do
      stub_actions(period: "7d")
      visit search_analytics_path(period: "7d")
    end

    it "preserves unknowns and range totals", :aggregate_failures do
      expect_action_summary("Total journeys" => "150", "Navigation" => "40", "Search" => "50", "Unclassified" => "60")
      expect(page).to have_content("Action breakdown collected for 1 of 2 UTC days")
      expect(chart_payload.fetch("datasets").pluck("data")).to eq([[nil, 40], [nil, 50], [60, 10]])
      expect(page).to have_content("bars do not add up to Total journeys")
    end

    it "provides a labelled data table", :aggregate_failures do
      table = find("details", text: "View search activity data").find("table", visible: :all)
      expect(table).to have_css("caption", text: "Search activity by day (UTC)", visible: :all)
      expect(table.all("tbody tr", visible: :all).map { |row| row.all("th, td", visible: :all).map { |cell| cell.text(:all) } }).to eq(expected_rows)
    end
  end

  context "without action collection" do
    let(:actions) do
      {
        available: false,
        coverage: { complete: false, collected_days: 0, expected_days: 1 },
        summary: { total: 100, navigation: nil, search: nil, unclassified: 100 },
        trend: [{ bucket: "2026-06-10T09:00:00Z", total: 100, navigation: nil, search: nil, unclassified: 100 }],
      }
    end

    it "retains the unclassified headline", :aggregate_failures do
      stub_actions
      visit search_analytics_path

      expect_action_summary("Total journeys" => "100", "Navigation" => "Unavailable", "Search" => "Unavailable", "Unclassified" => "100")
      expect(page).to have_content("Historical totals remain unclassified")
      expect(chart_payload.fetch("datasets").pluck("label")).to eq(%w[Unclassified])
    end
  end

  context "with an older backend response" do
    let(:actions) { nil }

    it "keeps totals without inventing a split", :aggregate_failures do
      stub_actions
      visit search_analytics_path

      expect_action_summary("Total journeys" => "1,240", "Navigation" => "Unavailable", "Search" => "Unavailable", "Unclassified" => "1,240")
      expect(chart_payload.fetch("datasets").pluck("label")).to eq(%w[Unclassified])
    end

    it "does not use legacy request counts", :aggregate_failures do
      stub_actions(journey_metrics: false)
      visit search_analytics_path

      expect_action_summary("Total journeys" => "Unavailable", "Navigation" => "Unavailable", "Search" => "Unavailable", "Unclassified" => "Unavailable")
      expect(page).to have_content("Search activity is unavailable for these dates")
      expect(page).not_to have_css("#activity-trend-heading ~ .search-analytics-chart-container")
    end
  end

  context "with a collected zero population" do
    let(:counts) { { total: 0, navigation: 0, search: 0, unclassified: 0 } }

    it "shows observed zeros, not unavailable", :aggregate_failures do
      stub_actions
      visit search_analytics_path

      expect_action_summary("Total journeys" => "0", "Navigation" => "0", "Search" => "0", "Unclassified" => "0")
      expect(page).to have_content("No journeys were recorded on the collected days")
      expect(chart_payload.fetch("datasets").pluck("data")).to eq([[0], [0], [0]])
    end
  end

  def stub_actions(view: "all", period: "24h", journey_metrics: true)
    body = JSON.parse(Rails.root.join("spec/fixtures/search_analytics/#{period}_#{view}.json").read)
    body["data"]["attributes"]["actions"] = actions
    body["data"]["attributes"]["availability"]["journey_metrics"] = journey_metrics
    stub_api_request("/search_analytics").with(query: { period:, view: })
      .to_return(status: 200, headers: { "content-type" => "application/json" }, body: body.to_json)
  end

  def expect_action_summary(values)
    within(".search-analytics-activity") do
      values.each do |label, value|
        expect(page).to have_css("section[aria-label='#{label}'] .search-analytics-metric__value", exact_text: value)
      end
    end
  end

  def expect_action_chart
    expect(chart_payload.fetch("datasets").pluck("label")).to eq(%w[Navigation Search Unclassified])
    expect(chart_payload.fetch("datasets").pluck("data")).to eq([[40], [50], [10]])
    expect(page).to have_css("#activity-trend-heading ~ .search-analytics-chart-container canvas[data-stacked='true'][role='img']")
  end

  def chart_payload
    JSON.parse(find("#activity-trend-heading ~ .search-analytics-chart-container canvas")["data-chart"])
  end
end
