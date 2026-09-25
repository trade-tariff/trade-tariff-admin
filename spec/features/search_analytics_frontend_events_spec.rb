RSpec.describe "Frontend search event widgets" do
  include_context "with UK service"

  let(:event_data) { JSON.parse(Rails.root.join("spec/fixtures/search_analytics/frontend_events.json").read) }

  def stub_events(data: event_data, view: "all", period: "24h", journeys: nil)
    body = JSON.parse(Rails.root.join("spec/fixtures/search_analytics/#{period}_#{view}.json").read)
    body["data"]["attributes"]["frontend_events"] = data
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

  it "shows an empty state instead of a blank actions pie", :aggregate_failures do
    event_data["actions"] = { "result_selected" => 0, "dont_know" => 0 }
    stub_events
    visit search_analytics_path
    expect(page).to have_content("No actions recorded.")
    expect(page).not_to have_css("canvas[data-chart-type='pie']")
  end

  it "does not turn a missing table into zero", :aggregate_failures do
    %w[outcomes selections question_counts].each { |key| event_data.delete(key) }
    stub_events
    visit search_analytics_path
    expect_missing_tables_are_absent
  end

  it "does not turn nil collections into zero", :aggregate_failures do
    %w[outcomes selections question_counts].each { |key| event_data[key] = nil }
    stub_events
    visit search_analytics_path
    expect_missing_tables_are_absent
  end

  it "uses each table total instead of the headline", :aggregate_failures do
    event_data["observed_journeys"] = 9
    event_data["question_counts"] = [{ "questions" => 1, "journeys" => 2 }, { "questions" => 2, "journeys" => 1 }]
    stub_events
    visit search_analytics_path
    expect_table_denominators
  end

  it "rounds row shares without changing the total", :aggregate_failures do
    assign_equal_count_rows
    stub_events
    visit search_analytics_path
    expect_rounded_share_rows
  end

  it "does not divide by zero for empty or zero counts", :aggregate_failures do
    assign_zero_count_rows
    stub_events
    visit search_analytics_path
    expect_zero_count_tables
  end

  it "does not percentage a table with a missing count", :aggregate_failures do
    remove_one_count_from_each_table
    stub_events
    visit search_analytics_path
    expect_incomplete_tables_have_no_shares
  end

  def expect_event_tables
    expect(page).to have_css("#frontend-events-heading", text: "Guided search events")
    expect(page).to have_content("Observed journeys: 4.")
    expect(page).to have_content("Observed browser sessions: 2.")
    expect(page).to have_content("Rank 1, Strong")
    expect(page).to have_content("Rank 2, Good")
    expect(table_rows("page-outcomes-table")).to eq([
      ["Outcome", "Page events", "Share of page events", "Average wait for page"],
      ["Question", "3", "60%", "1.5s"],
      ["Results", "2", "40%", "Unavailable"],
      ["Total", "5", "100%", "Not applicable"],
    ])
    expect(page.find("#page-outcomes-table").text).not_to include("1,240")
    expect(page).to have_content("The total row does not include average wait.")
    expect_action_chart
  end

  def expect_action_chart
    canvas = page.find(".search-analytics-actions-chart canvas[data-chart-type='pie'][role='img']")
    payload = JSON.parse(canvas["data-chart"])
    expect(payload["labels"]).to eq(["Result selections", "Don't know"])
    expect(payload["datasets"].first["data"]).to eq([3, 1])
    table = page.find("details", text: "View action data").find("table", visible: :all)
    expect(table.all("th, td", visible: :all).map { |cell| cell.text(:all) }).to eq(["Action", "Recorded events", "Result selections", "3", "Don't know", "1"])
    expect(table).to have_no_css("tfoot", visible: :all)
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

  def expect_missing_tables_are_absent
    expect(page).to have_no_css("#page-outcomes-table, #selection-rank-table, #question-distribution-table")
    expect(page).to have_content("Observed journeys: 4.")
    expect(page).to have_no_content("Not applicable")
  end

  def expect_table_denominators
    expect(page).to have_content("Search requests").and have_content("1,240")
    expect(page).to have_content("Observed journeys: 9.")
    expect(table_rows("page-outcomes-table")).to eq([
      ["Outcome", "Page events", "Share of page events", "Average wait for page"],
      ["Question", "3", "60%", "1.5s"],
      ["Results", "2", "40%", "Unavailable"],
      ["Total", "5", "100%", "Not applicable"],
    ])
    expect(table_rows("selection-rank-table")).to eq([
      ["Selection", "Recorded events", "Share of recorded selection events"],
      ["Rank 1, Strong", "2", "66.7%"],
      ["Rank 2, Good", "1", "33.3%"],
      ["Total", "3", "100%"],
    ])
    expect(table_rows("question-distribution-table")).to eq([
      ["Maximum reported questions", "Observed journeys", "Share of reported journeys"],
      ["1", "2", "66.7%"],
      ["2", "1", "33.3%"],
      ["Total", "3", "100%"],
    ])
    expect(page).to have_no_css("section[aria-labelledby='zero-search-terms-heading'] tfoot, .search-analytics-ai-cost__breakdown tfoot")
  end

  def assign_equal_count_rows
    event_data["outcomes"] = (1..3).map { |index| { "outcome" => "question_#{index}", "rendered_events" => 1, "average_navigation_ms" => 1_500 } }
    event_data["selections"] = (1..3).map { |index| { "result_rank" => index, "confidence" => "possible", "event_count" => 1 } }
    event_data["question_counts"] = (1..3).map { |index| { "questions" => index, "journeys" => 1 } }
  end

  def expect_rounded_share_rows
    %w[page-outcomes-table selection-rank-table question-distribution-table].each do |table_id|
      rows = table_rows(table_id)
      expect(rows[1..3].map { |row| row[2] }).to eq(["33.3%", "33.3%", "33.3%"])
      expect(rows.last[2]).to eq("100%")
    end
    expect(table_rows("page-outcomes-table").last).to eq(["Total", "3", "100%", "Not applicable"])
  end

  def assign_zero_count_rows
    event_data["outcomes"] = []
    event_data["selections"] = [{ "result_rank" => 1, "confidence" => "strong", "event_count" => 0 }]
    event_data["question_counts"] = []
  end

  def expect_zero_count_tables
    expect(table_rows("page-outcomes-table").last).to eq(["Total", "0", "Not applicable", "Not applicable"])
    expect(table_rows("selection-rank-table")).to include(["Rank 1, Strong", "0", "Not applicable"], ["Total", "0", "Not applicable"])
    expect(table_rows("question-distribution-table").last).to eq(["Total", "0", "Not applicable"])
    expect(page).to have_no_content("NaN")
  end

  def remove_one_count_from_each_table
    event_data["outcomes"][1]["rendered_events"] = nil
    event_data["selections"][0].delete("event_count")
    event_data["question_counts"][0]["journeys"] = nil
  end

  def expect_incomplete_tables_have_no_shares
    expect(table_rows("page-outcomes-table")).to eq([
      ["Outcome", "Page events", "Share of page events", "Average wait for page"],
      ["Question", "3", "Unavailable", "1.5s"],
      ["Results", "Unavailable", "Unavailable", "Unavailable"],
      ["Total", "Unavailable", "Unavailable", "Not applicable"],
    ])
    expect(table_rows("selection-rank-table")).to include(["Rank 2, Good", "1", "Unavailable"], %w[Total Unavailable Unavailable])
    expect(table_rows("question-distribution-table")).to include(%w[0 1 Unavailable], %w[Total Unavailable Unavailable])
  end

  def expect_missing_frontend_data
    expect(page).to have_content("Frontend events have not been collected for these dates")
    expect(page).to have_content("Opening this page does not start collection")
    expect(page).to have_css("section[aria-label='Search requests']", text: "1,240")
    within("section[aria-labelledby='frontend-events-heading']") do
      expect(page).not_to have_css("table")
      expect(page).not_to have_content("Share of page events")
      expect(page).not_to have_content("Share of recorded selection events")
      expect(page).not_to have_content("Share of reported journeys")
    end
  end

  def expect_empty_frontend_data
    expect(page).to have_content("No guided-search events were recorded for these collected days")
    expect(page).to have_content("This does not establish whether frontend telemetry was available")
    expect(page).not_to have_content("Frontend events have not been collected")
    expect(page).to have_no_css("#page-outcomes-table, #selection-rank-table, #question-distribution-table")
  end

  def table_rows(table_id)
    page.find("##{table_id}", visible: :all).all("tr", visible: :all).map do |row|
      row.all("th, td", visible: :all).map { |cell| cell.text(:all) }
    end
  end
end
