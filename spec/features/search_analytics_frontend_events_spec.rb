RSpec.describe "Frontend search event widgets" do
  include_context "with UK service"

  let(:event_data) { JSON.parse(Rails.root.join("spec/fixtures/search_analytics/frontend_events.json").read) }

  def stub_events(data: event_data, view: "all", period: "24h")
    body = JSON.parse(Rails.root.join("spec/fixtures/search_analytics/#{period}_#{view}.json").read)
    body["data"]["attributes"]["frontend_events"] = data
    stub_api_request("/search_analytics").with(query: { period:, view: })
      .to_return(status: 200, headers: { "content-type" => "application/json" }, body: body.to_json)
  end

  %w[all internal].each do |view|
    it "shows one frontend page-event count for #{view}", :aggregate_failures do
      stub_events(view:)
      visit search_analytics_path(period: "24h", view:)
      expect_event_tables
    end
  end

  it "does not show guided event widgets for Classic", :aggregate_failures do
    stub_events(view: "classic")
    visit search_analytics_path(period: "24h", view: "classic")
    expect(page).not_to have_css("#frontend-events-heading")
    expect(page).to have_content("Search volume")
  end

  it "does not show guided event widgets for an unsupported service", :aggregate_failures do
    event_data["coverage"]["supported"] = false
    stub_events
    visit search_analytics_path
    expect(page).not_to have_css("#frontend-events-heading")
  end

  it "retains existing metrics for older backend payloads", :aggregate_failures do
    stub_events(data: nil)
    visit search_analytics_path
    expect(page).not_to have_css("#frontend-events-heading")
    expect(page).to have_css("section[aria-label='Search requests']", text: "1,240")
  end

  it "keeps existing widgets when observed sessions are absent", :aggregate_failures do
    event_data.delete("observed_sessions")
    stub_events
    visit search_analytics_path
    expect(page).to have_content("Observed journeys: 4.").and have_no_content("Observed browser sessions")
    expect(page).to have_content("Rank 1, Strong")
  end

  it "shows missing frontend collection without hiding backend metrics", :aggregate_failures do
    event_data["available"] = false
    stub_events
    visit search_analytics_path
    expect_missing_frontend_data
  end

  it "reports frontend coverage independently of existing metrics", :aggregate_failures do
    event_data["coverage"].merge!("complete" => false, "expected_days" => 7)
    stub_events(period: "7d")
    visit search_analytics_path(period: "7d", view: "all")
    expect(page).to have_content("Frontend event coverage is incomplete")
    expect(page).to have_content("missing days are not zero-activity days")
  end

  it "does not interpret an empty successful query as missing collection", :aggregate_failures do
    event_data["observed_journeys"] = 0
    stub_events
    visit search_analytics_path
    expect_empty_frontend_data
  end

  it "keeps unknown question counts separate from zero and groups overflow", :aggregate_failures do
    stub_events
    visit search_analytics_path
    expect_question_chart
  end

  it "shows an empty state instead of a blank actions pie", :aggregate_failures do
    event_data["actions"] = { "result_selected" => 0, "dont_know" => 0 }
    stub_events
    visit search_analytics_path
    expect(page).to have_content("No actions recorded.")
    expect(page).not_to have_css("canvas[data-chart-type='pie']")
  end

  def expect_event_tables
    expect(page).to have_css("#frontend-events-heading", text: "Guided search events")
    expect(page).to have_content("Observed journeys: 4.")
    expect(page).to have_content("Observed browser sessions: 2.")
    expect(page).to have_content("Rank 1, Strong")
    expect(page).to have_content("Rank 2, Good")
    table = page.find("table", text: "Observed page outcomes")
    expect(table.all("thead th").map(&:text)).to eq(["Outcome", "Page events", "Average wait for page"])
    expect(table.all("tbody tr").map { |row| row.all("th, td").map(&:text) }).to eq([
      ["Question", "3", "1.5s"],
      ["Results", "2", "Unavailable"],
    ])
    expect_action_chart
  end

  def expect_action_chart
    canvas = page.find(".search-analytics-actions-chart canvas[data-chart-type='pie'][role='img']")
    payload = JSON.parse(canvas["data-chart"])
    expect(payload["labels"]).to eq(["Result selections", "Don't know"])
    expect(payload["datasets"].first["data"]).to eq([3, 1])
    table = page.find("details", text: "View action data").find("table", visible: :all)
    expect(table.text(:all)).to include("Result selections", "Don't know", "3", "1")
  end

  def expect_question_chart
    canvas = page.find("section[aria-labelledby='frontend-events-heading'] canvas[data-chart-type='bar'][role='img']")
    payload = JSON.parse(canvas["data-chart"])
    expect([canvas["data-x-axis-title"], canvas["data-y-axis-title"], canvas["data-hide-legend"]]).to eq(["Reported questions", "Journeys", "true"])
    expect(payload["labels"]).to eq(["Unknown", "0", "8+"])
    expect(payload["datasets"].first["data"]).to eq([1, 1, 2])
    table = page.find("details", text: "View question data").find("table", visible: :all)
    expect(table.text(:all)).to include("Maximum reported questions", "Unknown", "0", "8+")
  end

  def expect_missing_frontend_data
    expect(page).to have_content("Frontend events have not been collected for these dates")
    expect(page).to have_content("Opening this page does not start collection")
    expect(page).to have_css("section[aria-label='Search requests']", text: "1,240")
    within("section[aria-labelledby='frontend-events-heading']") { expect(page).not_to have_css("table") }
  end

  def expect_empty_frontend_data
    expect(page).to have_content("No guided-search events were recorded for these collected days")
    expect(page).to have_content("This does not establish whether frontend telemetry was available")
    expect(page).not_to have_content("Frontend events have not been collected")
  end
end
