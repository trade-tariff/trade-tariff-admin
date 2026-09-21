require "active_support/testing/time_helpers"

RSpec.describe "Search analytics dashboard" do
  include_context "with UK service"

  before do
    stub_search_analytics("24h", "all")
    stub_search_analytics("7d", "all")
    stub_search_analytics("30d", "all")
    stub_search_analytics("24h", "classic")
    stub_search_analytics("24h", "internal")
  end

  it "renders the default dashboard from the backend contract fixture", :aggregate_failures do
    visit search_analytics_path

    expect_default_dashboard_content
  end

  it "labels histogram latency as approximate and retains complete term results", :aggregate_failures do
    stub_histogram_analytics
    visit search_analytics_path(period: "30d", view: "all")

    expect_histogram_analytics
  end

  it "groups the compact date controls with the other top-row filters", :aggregate_failures do
    visit search_analytics_path

    expect(page).to have_css(".search-analytics-filters .search-analytics-date-range input#from[type='date']")
    expect(page).to have_css(".search-analytics-filters .search-analytics-date-range input#to[type='date']")
    expect(page).to have_css(".search-analytics-filters .search-analytics-date-range input[type='submit'][value='Apply dates']")
  end

  it "normalises unknown period and view values", :aggregate_failures do
    visit search_analytics_path(period: "invalid", view: "invalid")
    expect(page).to have_css("section[aria-label='Search requests']", text: "1,240")
    expect(JSON.parse(find(".search-analytics-charts canvas", match: :first)["data-chart"]).fetch("datasets").pluck("label")).to eq(%w[All])
  end

  it "shows missing data without fabricated zero metrics", :aggregate_failures do
    stub_api_request("/search_analytics").with(query: { period: "24h", view: "all" }).to_return(status: 404)
    visit search_analytics_path
    expect(page).to have_content("No collected search analytics are available for the selected dates.")
    expect(page).not_to have_css(".search-analytics-metrics")
  end

  it "renders each period link from fixture-backed data", :aggregate_failures do
    visit search_analytics_path

    expect_period_link("7 days", content: "8,420", query: "period=7d")
    expect_ai_cost_summary("$0.18")
    expect_period_link("30 days", content: "36,100", query: "period=30d")
  end

  it "renders each view link from fixture-backed data", :aggregate_failures do
    visit search_analytics_path

    expect_view_link("Classic", content: "classic term", value: "710")
    expect_view_link("Internal", content: "internal term", value: "530")
    expect_ai_cost_summary("$0.03")
  end

  context "with Internal volume below one percent of Classic volume" do
    let(:volume_counts) { { "all" => 100_001, "classic" => 100_000, "internal" => 1 } }

    %w[all classic internal].each do |view|
      context "when #{view} is selected" do
        before do
          stub_volume_analytics(view, volume_counts)
          visit search_analytics_path(period: "24h", view:)
        end

        it "plots only the selected view and retains hourly intervals", :aggregate_failures do
          payload = JSON.parse(find(".search-analytics-charts canvas", match: :first)["data-chart"])

          expect(payload.fetch("datasets")).to match([a_hash_including("label" => view.humanize, "data" => [volume_counts.fetch(view)] * 2)])
          expect(payload.fetch("labels")).to eq(["8am to 9am", "9am to 10am"])
          expect(page).to have_css("h2", text: "Search volume")
        end
      end
    end
  end

  it "retains rare non-zero failures, zero results and selections in the outcome trend", :aggregate_failures do
    stub_rare_outcomes
    visit search_analytics_path(period: "24h", view: "internal")
    payload = JSON.parse(all(".search-analytics-charts canvas").last["data-chart"])
    expect(payload.fetch("datasets").pluck("label")).to eq(["Completed", "Failed", "Zero result", "Selected"])
    expect(payload.fetch("datasets").drop(1).pluck("data")).to all(eq([1]))
  end

  it "plots question-only and unknown journeys as distinct outcome series", :aggregate_failures do
    stub_outcome_states
    visit search_analytics_path(period: "24h", view: "internal")
    payload = JSON.parse(all(".search-analytics-charts canvas").last["data-chart"])
    expect(payload.fetch("datasets").pluck("label")).to eq(["Completed", "Failed", "Question only", "Unknown", "Zero result", "Selected"])
    expect(payload.fetch("datasets").pluck("data")).to all(eq([1]))
  end

  it "presents a total-cost chart and business-focused cost tables", :aggregate_failures do
    visit search_analytics_path

    expect_business_cost_presentation
  end

  it "presents daily cost data as dates without meaningless midnight times", :aggregate_failures do
    visit search_analytics_path(period: "7d", view: "all")
    table = find(".search-analytics-ai-cost__chart details table", visible: :all)

    expect(table.text(:all)).to include("4 June 2026", "10 June 2026")
    expect(table.text(:all)).not_to include("00:00", " at ", "Date and time")
  end

  it "aligns AI cost with search requests without introducing journey breakdowns", :aggregate_failures do
    stub_journey_analytics
    visit search_analytics_path(period: "24h", view: "internal")
    expect(page).to have_css("section[aria-label='Search requests']", text: "6")
    expect(page).to have_css("#ai-cost-heading", text: "AI cost")
    expect_no_journey_breakdown
  end

  it "withholds Internal cost figures from an unmatched collection", :aggregate_failures do
    stub_journey_analytics(journey_metrics: false)
    visit search_analytics_path(period: "24h", view: "internal")
    expect(page).not_to have_css("#ai-cost-heading")
    expect(page).to have_content("Older request counts are not journey counts")
    expect(page).to have_css("section[aria-label='Search requests']", text: "Unavailable")
  end

  [false, nil].each do |available|
    it "withholds legacy statuses when journeys are unavailable (#{available.inspect})", :aggregate_failures do
      stub_journey_analytics(journey_metrics: available)
      visit search_analytics_path(period: "24h", view: "internal")
      expect_unavailable_metric("Search requests")
    end

    it "withholds legacy step outcomes when journey outcomes are unavailable (#{available.inspect})", :aggregate_failures do
      stub_journey_analytics(journey_outcomes: available)
      visit search_analytics_path(period: "24h", view: "internal")
      expect(page).to have_content("Journey outcomes have not been collected for these dates")
      expect(page.find(".search-analytics-charts section", text: "Outcome trend")).not_to have_css("canvas")
      expect(page).to have_css("section[aria-label='Search requests']", text: "6")
    end

    it "withholds unmatched costs while retaining current journey counts (#{available.inspect})", :aggregate_failures do
      stub_journey_analytics(costs_match_view: available)
      visit search_analytics_path(period: "24h", view: "internal")
      expect(page).to have_css("section[aria-label='Search requests']", text: "6")
      expect(page).not_to have_css("#ai-cost-heading")
      expect(page).to have_content("Matching AI cost data is not available for the selected view.")
    end
  end

  it "shows matching outcome days when outcome coverage is incomplete", :aggregate_failures do
    stub_incomplete_outcome_analytics
    visit search_analytics_path(period: "24h", view: "internal")
    expect(page).to have_content("Outcome figures describe collected days only")
    expect(page.find(".search-analytics-charts section", text: "Outcome trend")).to have_css("canvas")
  end

  [true, false, nil].each do |available|
    it "hides AI costs and cost notices for Classic (#{available.inspect})", :aggregate_failures do
      stub_journey_analytics(view: "classic", costs_match_view: available)
      visit search_analytics_path(period: "24h", view: "classic")
      expect(page).not_to have_css(".search-analytics-ai-cost", visible: :all)
      expect(page).not_to have_content("Matching AI cost data")
      expect(page).to have_css("section[aria-label='Search requests']", text: "6")
    end
  end

  it "keeps journey availability notices for Classic without referring to AI costs", :aggregate_failures do
    stub_journey_analytics(view: "classic", journey_metrics: false)
    visit search_analytics_path(period: "24h", view: "classic")
    expect(page).to have_content("Search journeys need to be collected")
    expect(page).not_to have_content("AI cost")
    expect_unavailable_metric("Search requests")
  end

  %w[internal all].each do |view|
    it "retains AI cost collection guidance for #{view}", :aggregate_failures do
      stub_journey_analytics(view:, journey_metrics: false)
      visit search_analytics_path(period: "24h", view:)
      expect(page).to have_content("Search journeys and their AI costs need to be collected for this date range.")
      expect(page).not_to have_css(".search-analytics-ai-cost", visible: :all)
    end
  end

  it "shows zero recorded costs when Internal has no AI calls", :aggregate_failures do
    stub_internal_without_ai_calls
    visit search_analytics_path(period: "24h", view: "internal")

    expect(page).to have_css("#ai-cost-heading", text: "AI cost")
    expect(page).to have_css("section[aria-label='Estimated AI cost']", text: "$0.00")
    expect(page).not_to have_css(".search-analytics-ai-cost__breakdown")
  end

  it "filters zero search terms to search terms", :aggregate_failures do
    visit search_analytics_path

    click_link "Search terms"

    expect(current_url).to include("term_filter=search_terms")
    expect(improvement_term_queries).to include("yoga ball", "phone case")
    expect(improvement_term_queries).not_to include("3926909090")
  end

  it "filters zero search terms to item IDs", :aggregate_failures do
    visit search_analytics_path

    click_link "Item IDs"

    expect(current_url).to include("term_filter=item_ids")
    expect(improvement_term_queries).to include("3926909090")
    expect(improvement_term_queries).not_to include("yoga ball", "phone case")
  end

  it "paginates improvement terms", :aggregate_failures do
    visit search_analytics_path

    expect_first_improvement_term_page
    expect_search_term_pagination
    expect_second_improvement_term_page_after_next
  end

  it "shows incomplete coverage and unavailable range metrics", :aggregate_failures do
    stub_incomplete_analytics
    visit search_analytics_path(period: "30d", view: "all")
    expect_incomplete_analytics
  end

  it "keeps other metrics when AI cost rows are absent", :aggregate_failures do
    stub_missing_cost_query_analytics
    visit search_analytics_path(period: "30d", view: "all")
    expect(page).to have_css("section[aria-label='Search requests']")
    expect(page).to have_content("AI cost data has not been collected for these dates")
    expect(page).not_to have_css("#ai-cost-heading")
  end

  context "with custom date ranges" do
    include ActiveSupport::Testing::TimeHelpers

    around { |example| travel_to(Time.utc(2026, 9, 15, 10), &example) }

    before do
      stub_date_range_analytics("all")
      stub_date_range_analytics("internal")
    end

    it "provides native date pickers bounded by yesterday", :aggregate_failures do
      visit search_analytics_path
      expect(page).to have_css("input#from[type='date'][max='2026-09-14'][required]")
      expect(page).to have_css("input#to[type='date'][max='2026-09-14'][required]")
    end

    it "applies and retains the selected dates", :aggregate_failures do
      visit search_analytics_path
      fill_in "From", with: "2026-09-01"
      fill_in "To", with: "2026-09-03"
      click_button "Apply dates"
      expect_selected_date_range
    end

    it "preserves dates through pagination and term and view filters", :aggregate_failures do
      visit search_analytics_path(period: "custom", from: "2026-09-01", to: "2026-09-03", view: "all")
      expect_dates_after_filter("Next")
      expect_dates_after_filter("Item IDs")
      expect_dates_after_filter("Internal")
    end

    it "clears custom dates when choosing a preset", :aggregate_failures do
      visit search_analytics_path(period: "custom", from: "2026-09-01", to: "2026-09-03", view: "all")
      click_link "7 days"
      expect(current_url).not_to include("from=", "to=")
      expect(page).to have_field("From", with: "2026-09-08")
      expect(page).to have_field("To", with: "2026-09-14")
    end

    it "shows validation errors without fabricated zero metrics", :aggregate_failures do
      stub_invalid_date_range
      visit search_analytics_path(period: "custom", from: "2026-09-03", to: "2026-09-01", view: "all")
      expect_accessible_date_errors
    end
  end

  def expect_accessible_date_errors
    expect(page).to have_field("From", with: "2026-09-03")
    expect(page).not_to have_css(".search-analytics-metrics")
    expect(page).to have_css("#date-range-error", text: "From must be on or before To.")
    %w[from to].each do |name|
      expect(page).to have_css(".govuk-error-summary a[href='##{name}']")
      expect(page).to have_css("##{name}[aria-invalid='true'][aria-describedby~='date-range-error'].govuk-input--error")
    end
  end

  def expect_unavailable_metric(label)
    within("section[aria-label='#{label}']") do
      expect(page).to have_content("Unavailable")
      expect(page).not_to have_css(".govuk-tag, .govuk-body-s")
    end
  end

  def expect_no_journey_breakdown
    expect(page).not_to have_css("section[aria-label='Guided searches'], section[aria-label='Exact-code lookups'], section[aria-label='AI-assisted searches']")
    expect(page).not_to have_content("Each step counts as a search request")
  end

  def stub_internal_without_ai_calls
    body = JSON.parse(Rails.root.join("spec/fixtures/search_analytics/24h_classic.json").read)
    body["data"]["attributes"]["view"] = "internal"
    stub_api_request("/search_analytics").with(query: { period: "24h", view: "internal" })
      .to_return(status: 200, headers: { "content-type" => "application/json" }, body: body.to_json)
  end

  def stub_journey_analytics(journey_metrics: true, costs_match_view: true, journey_outcomes: true, view: "internal")
    body = JSON.parse(Rails.root.join("spec/fixtures/search_analytics/24h_#{view}.json").read)
    body["data"]["attributes"]["availability"].merge!("journey_metrics" => journey_metrics, "costs_match_view" => costs_match_view, "journey_outcomes" => journey_outcomes)
    body["data"]["attributes"]["summary"].merge!("searches" => 6, "requests" => 32)
    body["data"]["attributes"]["journeys"] = { "count" => 6 }
    stub_api_request("/search_analytics").with(query: { period: "24h", view: })
      .to_return(status: 200, headers: { "content-type" => "application/json" }, body: body.to_json)
  end

  def stub_incomplete_outcome_analytics
    body = JSON.parse(Rails.root.join("spec/fixtures/search_analytics/24h_internal.json").read)
    body["data"]["attributes"]["availability"]["journey_outcomes"] = true
    body["data"]["attributes"]["availability"]["journey_outcome_coverage"] = { "complete" => false, "collected_days" => 1, "expected_days" => 2 }
    stub_api_request("/search_analytics").with(query: { period: "24h", view: "internal" })
      .to_return(status: 200, headers: { "content-type" => "application/json" }, body: body.to_json)
  end

  def stub_outcome_states
    body = JSON.parse(Rails.root.join("spec/fixtures/search_analytics/24h_internal.json").read)
    body["data"]["attributes"]["summary"]["searches"] = 4
    body["data"]["attributes"]["trends"]["outcomes"].each { |row| row.merge!(%w[completed failed nonterminal unknown zero_result selected].index_with { 1 }) }
    stub_api_request("/search_analytics").with(query: { period: "24h", view: "internal" })
      .to_return(status: 200, headers: { "content-type" => "application/json" }, body: body.to_json)
  end

  def stub_rare_outcomes
    body = JSON.parse(Rails.root.join("spec/fixtures/search_analytics/24h_internal.json").read)
    body["data"]["attributes"]["trends"]["outcomes"].each { |row| row.merge!("completed" => 1000, "failed" => 1, "zero_result" => 1, "selected" => 1) }
    stub_api_request("/search_analytics").with(query: { period: "24h", view: "internal" })
      .to_return(status: 200, headers: { "content-type" => "application/json" }, body: body.to_json)
  end

  def stub_volume_analytics(view, counts)
    body = JSON.parse(Rails.root.join("spec/fixtures/search_analytics/24h_all.json").read)
    body["data"]["attributes"]["view"] = view
    body["data"]["attributes"]["trends"]["volume"].each { |row| row.merge!(counts) }
    stub_api_request("/search_analytics").with(query: { period: "24h", view: })
      .to_return(status: 200, headers: { "content-type" => "application/json" }, body: body.to_json)
  end

  def stub_date_range_analytics(view)
    body = JSON.parse(Rails.root.join("spec/fixtures/search_analytics/24h_#{view}.json").read)
    body["data"]["attributes"].merge!("period" => "custom", "bucket_size" => "day")
    body["data"]["attributes"]["coverage"] = { "from" => "2026-09-01", "to" => "2026-09-03", "expected_days" => 3, "collected_days" => 3, "complete" => true }
    stub_api_request("/search_analytics")
      .with(query: { period: "custom", from: "2026-09-01", to: "2026-09-03", view: })
      .to_return(status: 200, headers: { "content-type" => "application/json" }, body: body.to_json)
  end

  def stub_invalid_date_range
    stub_api_request("/search_analytics")
      .with(query: { period: "custom", from: "2026-09-03", to: "2026-09-01", view: "all" })
      .to_return(status: 400, headers: { "content-type" => "application/json" }, body: { errors: [{ detail: "From must be on or before To." }] }.to_json)
  end

  def expect_selected_date_range
    expect(current_url).to include("from=2026-09-01", "to=2026-09-03", "period=custom")
    expect(page).to have_field("From", with: "2026-09-01")
    expect(page).to have_field("To", with: "2026-09-03")
  end

  def expect_dates_after_filter(label)
    click_link label
    expect_selected_date_range
  end

  def stub_histogram_analytics
    body = JSON.parse(Rails.root.join("spec/fixtures/search_analytics/30d_all.json").read)
    attributes = body.fetch("data").fetch("attributes")
    attributes["availability"] = { "latency_percentiles_approximate" => true, "terms_complete" => { "search_terms" => true, "item_ids" => true } }
    attributes["summary"]["p90_latency_ms"] = 29.6
    stub_api_request("/search_analytics").with(query: { period: "30d", view: "all" })
      .to_return(status: 200, headers: { "content-type" => "application/json" }, body: body.to_json)
  end

  def expect_histogram_analytics
    expect(page).to have_css("section[aria-label='P90 latency (approx.)']", text: "29.6ms")
    expect(page).not_to have_css("p.govuk-body", text: "P90 latency is approximate")
    expect(page).to have_css("details", text: "About 90% of measured searches finished within this time.", visible: :all)
    expect(page).not_to have_css("details", text: "Latency tags", visible: :all)
    expect(page).not_to have_css("details", text: "histogram", visible: :all)
    expect(page).not_to have_content("Term rankings are unavailable")
    expect(improvement_term_queries).not_to be_empty
  end

  def stub_missing_cost_query_analytics
    body = JSON.parse(Rails.root.join("spec/fixtures/search_analytics/30d_all.json").read)
    attributes = body.fetch("data").fetch("attributes")
    attributes["coverage"] = {
      "complete" => false,
      "expected_days" => 30,
      "collected_days" => 30,
      "queries" => { "ai_cost_trend" => { "collected_days" => 0, "complete" => false } },
    }
    attributes["ai_costs"] = { "summary" => { "total_cost_usd" => 0, "complete" => false }, "trend" => [], "operations" => [] }
    stub_api_request("/search_analytics").with(query: { period: "30d", view: "all" })
      .to_return(status: 200, headers: { "content-type" => "application/json" }, body: body.to_json)
  end

  def stub_incomplete_analytics
    body = JSON.parse(Rails.root.join("spec/fixtures/search_analytics/30d_all.json").read)
    attributes = body.fetch("data").fetch("attributes")
    attributes["coverage"] = { "complete" => false, "expected_days" => 30, "collected_days" => 2 }
    attributes["availability"] = { "range_percentiles" => false, "terms_complete" => { "search_terms" => false } }
    attributes["summary"]["p90_latency_ms"] = nil
    attributes["ai_costs"] = { "summary" => { "assisted_searches" => 2, "total_cost_usd" => 0.01, "p90_cost_usd" => nil } }
    attributes["improvement_terms"] = []
    stub_api_request("/search_analytics").with(query: { period: "30d", view: "all" })
      .to_return(status: 200, headers: { "content-type" => "application/json" }, body: body.to_json)
  end

  def expect_incomplete_analytics
    expect(page).to have_content("2 of 30 UTC days have stored results")
    expect(page).to have_content("Some widgets may cover fewer days")
    expect(page).to have_content("Missing days are not zero-traffic days")
    expect(page).to have_content("Range percentiles are unavailable")
    expect_unavailable_metric("P90 latency")
    expect(page).not_to have_content("P90 cost per search")
    expect(page).not_to have_content("Average cost per search")
    expect(page).to have_content("Term rankings are unavailable")
  end

  def stub_search_analytics(period, view)
    stub_api_request("/search_analytics")
      .with(query: { period:, view: })
      .to_return(
        status: 200,
        headers: { "content-type" => "application/json; charset=utf-8" },
        body: Rails.root.join("spec/fixtures/search_analytics/#{period}_#{view}.json").read,
      )
  end

  def non_empty_chart_payloads
    page.all("canvas.search-analytics-chart").filter_map do |canvas|
      payload = JSON.parse(canvas["data-chart"])
      payload if payload.fetch("labels").any? && payload.fetch("datasets").all? { |dataset| dataset.fetch("data").any? }
    end
  end

  def chart_datasets
    page.all("canvas.search-analytics-chart").flat_map do |canvas|
      JSON.parse(canvas["data-chart"]).fetch("datasets")
    end
  end

  def improvement_term_queries
    page.all("[data-improvement-term-query]").map(&:text)
  end

  def expect_first_improvement_term_page
    expect(improvement_term_queries).to include("bike seat", "yoga ball")
    expect(improvement_term_queries).not_to include("3926909090", "storage box")
  end

  def expect_second_improvement_term_page
    expect(improvement_term_queries).to include("storage box")
    expect(improvement_term_queries).not_to include("3926909090", "bike seat")
  end

  def expect_search_term_pagination
    expect(page).to have_css(".govuk-pagination__list")
    expect(page).to have_link("1", class: "govuk-pagination__link")
    expect(page).to have_link("2", class: "govuk-pagination__link")
  end

  def expect_second_improvement_term_page_after_next
    click_link "Next"
    expect(current_url).to include("page=2")
    expect(current_url).not_to include("term_page")
    expect_second_improvement_term_page
  end

  def expect_default_dashboard_content
    expect(page).to have_content("Search dashboard")
    expect(page).to have_content("Search requests")
    expect(page).to have_content("1,240")
    expect(page).to have_content("Failure rate")
    expect(page).to have_content("1.2%")
    expect(page).not_to have_content("Query window ended")
    expect(page).to have_css(".govuk-details", text: "How these metrics are calculated")
    expect(page).to have_css(".govuk-summary-list__row", text: "Zero-result rate", visible: :all)
    expect(page).to have_css(".govuk-summary-list__row", text: "no commodity results", visible: :all)
    expect(page).to have_css(".govuk-summary-list__row", text: "Selection rate", visible: :all)
    expect(page).to have_css(".govuk-summary-list__row", text: "Result selections divided by eligible searches.", visible: :all)
    expect(page).to have_content("Can exceed 100% when users open more than one result.")
    expect(page).to have_content("Zero search terms")
    expect(page).not_to have_css("section[aria-labelledby='zero-search-terms-heading']", text: "Selection rate")
    expect(page).not_to have_css("section[aria-labelledby='zero-search-terms-heading']", text: "Searches")
    expect(page).to have_css("section[aria-labelledby='zero-search-terms-heading']", text: "Zero-result searches")
    expect(page).not_to have_content("Searches by view")
    expect(page).not_to have_content("Searches by request source")
    expect(page).not_to have_content("Volume by request source")
    expect(page).to have_content("bike seat")
    expect(page).not_to have_css("section[aria-labelledby='zero-search-terms-heading']", text: "3926909090")
    expect(page).to have_css("#backend-questions-heading", text: "Backend questions per journey")
    expect(page).to have_css(".search-analytics-chart-container", count: 4)
    expect(page).to have_css("section[aria-labelledby='ai-cost-heading']", text: "Known AI cost")
    expect(page).to have_content("$0.03")
    expect(page).not_to have_content("Average cost per search")
    expect(page).not_to have_content("P90 cost per search")
    expect(page).not_to have_content("Known cost only")
    expect(page).not_to have_content("Pricing was available")
    expect(page).to have_css("canvas[data-chart-type='bar'][data-y-axis-format='currency']:not([data-stacked])")
    expect(page).to have_css(".govuk-details", text: "View AI cost chart data")
    expect(page).not_to have_css(".search-analytics-ai-cost__breakdown", text: "24,500")
    expect(page).to have_css(".search-analytics-ai-cost__breakdown td.govuk-table__cell--numeric", exact_text: "$0.02")
    expect(page).to have_css(".search-analytics-ai-cost__breakdown td.govuk-table__cell--numeric", exact_text: "<$0.01")
    expect(page).not_to have_css(".search-analytics-table-detail")
    expect(page).to have_content("Classic")
    expect(page).to have_content("Internal")
    expect(page).to have_link("Search terms")
    expect(page).to have_link("Item IDs")
    expect(page).not_to have_link("All", href: /term_filter/)
    expect(page).to have_link("Next")
    expect(chart_datasets).to all(include("borderColor"))
    expect(chart_datasets.pluck("label")).not_to include("Frontend-routed", "Direct backend / non-frontend", "Unknown")
    expect(non_empty_chart_payloads.size).to eq(4)
  end

  def expect_period_link(label, content:, query:)
    click_link label
    expect(page).to have_content(content)
    expect(current_url).to include(query)
  end

  def expect_view_link(label, content:, value:)
    click_link label
    expect(page).to have_content(content)
    expect(page).to have_content(value)
  end

  def expect_business_cost_presentation
    chart = find("canvas[data-y-axis-format='currency']")
    expect(JSON.parse(chart["data-chart"]).fetch("datasets").pluck("label")).to eq(["Estimated AI cost"])
    expect(page).to have_content("Total recorded AI cost in US dollars for these journeys during the selected period")
    expect(page).not_to have_content("excluding analytics collection costs")
    expect(page).to have_css(".search-analytics-ai-cost__breakdown", text: "AI-assisted search")
    expect(page).to have_css(".search-analytics-ai-cost__breakdown", text: "Search matching preparation")
    expect(page).to have_css("#ai-cost-models-heading", text: "Cost by model")
    expect(page).to have_css("section[aria-labelledby='ai-cost-models-heading']", text: "gpt-5.4")
    expect(page.all("section[aria-labelledby='ai-cost-breakdown-heading'] thead th").map(&:text)).to eq(%w[Operation Calls Cost Share])
    expect(page.all(".search-analytics-ai-cost__chart details thead th", visible: :all).map { |header| header.text(:all) }).to eq(["Date and hour (UTC)", "Estimated AI cost"])
  end

  def expect_ai_cost_summary(total_cost)
    expect(page).to have_css("section[aria-labelledby='ai-cost-heading']", text: "Estimated AI cost")
    expect(page).to have_content(total_cost)
  end
end
