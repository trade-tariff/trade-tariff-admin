RSpec.describe "Search-only zero-result rate" do
  include_context "with UK service"

  let(:rate) { 0.6 }
  let(:search_only) { true }
  let(:coverage) { { complete: false, collected_days: 2, expected_days: 7 } }
  let(:standalone) { false }

  before do
    body = JSON.parse(Rails.root.join("spec/fixtures/search_analytics/24h_all.json").read)
    attributes = body.fetch("data").fetch("attributes")
    attributes.fetch("summary")["zero_result_rate"] = rate
    attributes["availability"] = (attributes["availability"] || {}).merge(
      zero_result_rate_search_only: search_only,
      zero_result_rate_coverage: coverage,
    )
    if standalone
      attributes["summary"].merge!("searches" => nil, "failure_rate" => nil, "selection_rate" => nil, "p90_latency_ms" => nil)
      attributes["availability"].merge!("journey_metrics" => false, "costs_match_view" => false)
      attributes["actions"] = { "available" => false, "summary" => nil, "trend" => [] }
    end
    stub_api_request("/search_analytics").with(query: { period: "24h", view: "all" })
      .to_return(status: 200, body: body.to_json, headers: { "content-type" => "application/json" })
    visit search_analytics_path
  end

  it "shows the corrected rate, population and collection coverage", :aggregate_failures do
    expect(page).to have_css("section[aria-label='Zero-result rate']", text: "60%")
    expect(page).to have_content("Zero-result rate covers 2 of 7 UTC days.")
    expect(page).to have_css(".govuk-summary-list__row", text: "Exact matches, intermediate questions and failed or degraded requests are excluded.", visible: :all)
    expect(page).to have_css(".govuk-summary-list__row", text: "Results at any tariff level count as items.", visible: :all)
    expect(page).to have_css(".govuk-summary-list__row", text: "The rate counts frontend search responses, not unique journeys.", visible: :all)
  end

  context "with only zero-result data" do
    let(:standalone) { true }

    it "shows the rate while leaving unrelated metrics unavailable", :aggregate_failures do
      expect(page).to have_css("section[aria-label='Zero-result rate']", text: "60%")
      ["Total journeys", "Failure rate", "Selection rate", "P90 latency (approx.)"].each do |label|
        expect(page).to have_css("section[aria-label='#{label}']", text: "Unavailable")
      end
      expect(page).not_to have_css("#ai-cost-heading")
    end
  end

  context "with no empty results" do
    let(:rate) { 0.0 }
    let(:coverage) { { complete: true, collected_days: 1, expected_days: 1 } }

    it "shows an observed zero without a missing-data warning", :aggregate_failures do
      expect(page).to have_css("section[aria-label='Zero-result rate']", text: "0%")
      expect(page).not_to have_content("Zero-result rate covers")
    end
  end

  context "without a completed-search denominator" do
    let(:rate) { nil }

    it "shows unavailable without a status tag", :aggregate_failures do
      expect(page).to have_css("section[aria-label='Zero-result rate']", text: "Unavailable")
      expect(page).not_to have_css("section[aria-label='Zero-result rate'] .govuk-tag")
    end
  end

  context "with an older backend" do
    let(:search_only) { nil }
    let(:coverage) { nil }

    it "does not present the legacy rate under the new definition" do
      expect(page).to have_css("section[aria-label='Zero-result rate']", text: "Unavailable")
    end
  end
end
