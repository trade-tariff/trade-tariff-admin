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

  it "renders each period link from fixture-backed data", :aggregate_failures do
    visit search_analytics_path

    expect_period_link("7 days", content: "8,420", query: "period=7d")
    expect_period_link("30 days", content: "36,100", query: "period=30d")
  end

  it "renders each view link from fixture-backed data", :aggregate_failures do
    visit search_analytics_path

    expect_view_link("Classic", content: "classic term", value: "710")
    expect_view_link("Internal", content: "internal term", value: "530")
  end

  it "filters improvement terms to non-numeric searches", :aggregate_failures do
    visit search_analytics_path

    click_link "Non-numeric"

    expect(current_url).to include("term_filter=non_numeric")
    expect(improvement_term_queries).to include("yoga ball", "phone case")
    expect(improvement_term_queries).not_to include("3926909090")
  end

  it "paginates improvement terms", :aggregate_failures do
    visit search_analytics_path

    expect_first_improvement_term_page
    expect_search_term_pagination
    expect_second_improvement_term_page_after_next
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
    expect(improvement_term_queries).to include("3926909090")
    expect(improvement_term_queries).not_to include("ceramic mug")
  end

  def expect_second_improvement_term_page
    expect(improvement_term_queries).to include("ceramic mug")
    expect(improvement_term_queries).not_to include("3926909090")
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
    expect(page).to have_content("Searches")
    expect(page).to have_content("1,240")
    expect(page).to have_content("Failure rate")
    expect(page).to have_content("1.2%")
    expect(page).to have_content("Generated 10 June 2026 at 09:55")
    expect(page).not_to have_content("Query window ended")
    expect(page).to have_css(".govuk-details", text: "How these metrics are calculated")
    expect(page).to have_css(".govuk-summary-list__row", text: "Zero-result rate", visible: :all)
    expect(page).to have_css(".govuk-summary-list__row", text: "Completed searches with no results divided by completed searches.", visible: :all)
    expect(page).to have_css(".govuk-summary-list__row", text: "Selection rate", visible: :all)
    expect(page).to have_css(".govuk-summary-list__row", text: "Result selections divided by eligible searches.", visible: :all)
    expect(page).to have_content("Can exceed 100% when users open more than one result.")
    expect(page).to have_content("Zero search terms")
    expect(page).not_to have_css("section[aria-labelledby='zero-search-terms-heading']", text: "Selection rate")
    expect(page).not_to have_css("section[aria-labelledby='zero-search-terms-heading']", text: "Searches")
    expect(page).to have_css("section[aria-labelledby='zero-search-terms-heading']", text: "Zero-result searches")
    expect(page).to have_content("Searches by view")
    expect(page).to have_content("3926909090")
    expect(page).to have_css(".search-analytics-chart-container", count: 2)
    expect(page).to have_css(".search-analytics-view-summary")
    expect(page).to have_css(".search-analytics-view-summary__table")
    expect(page).to have_content("Classic")
    expect(page).to have_content("Internal")
    expect(page).to have_link("Non-numeric")
    expect(page).to have_link("Next")
    expect(chart_datasets).to all(include("borderColor"))
    expect(non_empty_chart_payloads.size).to eq(2)
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
end
