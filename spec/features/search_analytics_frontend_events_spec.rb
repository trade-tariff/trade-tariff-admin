RSpec.describe "Frontend search event widgets" do
  include_context "with UK service"

  let(:event_data) { JSON.parse(Rails.root.join("spec/fixtures/search_analytics/frontend_events.json").read) }

  def stub_events(data: event_data, view: "all", period: "24h", journeys: nil, question_outcomes: nil)
    body = JSON.parse(Rails.root.join("spec/fixtures/search_analytics/#{period}_#{view}.json").read)
    body["data"]["attributes"]["frontend_events"] = data
    body["data"]["attributes"]["question_outcomes"] = question_outcomes || default_question_outcomes
    body["data"]["attributes"]["journeys"] = journeys if journeys
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
    stub_events(view: "classic", journeys: { "question_counts" => [{ "questions" => 1, "journeys" => 4 }] })
    visit search_analytics_path(period: "24h", view: "classic")
    expect(page).to have_no_css("#frontend-events-heading").and have_no_css("#backend-questions-heading")
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

  it "shows unavailable question rates instead of a blank actions pie", :aggregate_failures do
    stub_events(question_outcomes: empty_question_outcomes)
    visit search_analytics_path
    expect_unavailable_question_rates
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
    expect(page).to have_css("#question-outcome-rates", text: "Question outcome rates")
    expect(page).to have_content("questions shown")
    canvas = page.find("#question-outcome-rates ~ .search-analytics-chart-container canvas[data-chart-type='bar'][data-y-axis-format='percent']")
    payload = JSON.parse(canvas["data-chart"])
    expect(payload["labels"]).to eq(["Question answer rate", "Question \"I don't know\" rate", "Question abandonment rate"])
    expect(payload["datasets"].first["data"]).to eq([60.0, 20.0, 20.0])
    expect(page.find("details", text: "View question outcome data", visible: :all).text(:all)).to include("Question answer rate", "6", "60%", "Question abandonment rate", "2", "20%")
    expect(page).not_to have_css("canvas[data-chart-type='pie']")
  end

  def empty_question_outcomes
    {
      "supported" => true,
      "available" => true,
      "denominator" => 0,
      "counts" => { "server_accepted" => 0, "dont_know" => 0, "unanswered" => 0 },
      "percentages" => nil,
      "percentage_status" => "unavailable",
      "coverage" => { "complete" => true },
    }
  end

  def expect_unavailable_question_rates
    expect(page).to have_content("No questions were shown on the collected days. Rates are unavailable.")
    expect(page).not_to have_css("#question-outcome-rates ~ .search-analytics-chart-container canvas")
    expect(page).not_to have_css("canvas[data-chart-type='pie']")
  end

  def default_question_outcomes
    {
      "supported" => true,
      "available" => true,
      "denominator" => 10,
      "counts" => { "server_accepted" => 6, "dont_know" => 2, "unanswered" => 2 },
      "percentages" => { "server_accepted" => 60.0, "dont_know" => 20.0, "unanswered" => 20.0 },
      "percentage_status" => "available",
      "coverage" => { "complete" => true },
    }
  end

  def expect_question_chart
    canvas = page.find("canvas[data-x-axis-title='Reported questions'][data-chart-type='bar'][role='img']")
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
