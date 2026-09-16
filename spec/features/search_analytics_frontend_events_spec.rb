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
    it "shows separate rendered and visible observations for #{view}", :aggregate_failures do
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
    expect(page).to have_content("Frontend coverage: 1 of 7 complete UTC days collected.")
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
    table = page.find("table", text: "Reported questions per observed journey")
    expect(table.all("tbody tr").map { |row| row.all("th, td").map(&:text) }).to eq([["Unknown", "1"], ["0", "1"], ["8+", "2"]])
    expect(page).to have_content("this is not a count of answered questions")
  end

  def expect_event_tables
    expect(page).to have_css("#frontend-events-heading", text: "Guided search events")
    table = page.find("table", text: "Observed page outcomes")
    expect(table.all("tbody tr").map { |row| row.all("th, td").map(&:text) }).to eq([
      ["Question", "3", "2", "2", "2", "1.5s"],
      ["Results", "2", "0", "2", "0", "Unavailable"],
    ])
    expect(page).to have_content("not completion or abandonment rates")
    expect(page.find(".govuk-summary-list__row", text: "Result selection events")).to have_css("dd", exact_text: "3")
    expect(page.find(".govuk-summary-list__row", text: "Don't know events")).to have_css("dd", exact_text: "1")
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
