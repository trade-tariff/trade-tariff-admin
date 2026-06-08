RSpec.describe SearchDiagnosticsHelper do
  describe "#search_diagnostic_event_summary" do
    it "summarises query preparation and expansion events" do
      expect(query_preparation_summaries).to eq(expected_query_preparation_summaries)
    end

    it "summarises model, intercept, retrieval leg, selection and failure events" do
      expect(operational_summaries).to eq(expected_operational_summaries)
    end

    it "uses readable labels for generic event names" do
      expect(summary("unknown_event", query: "horse")).to eq("Unknown event")
    end

    it "does not render awkward query expansion copy when a query value is missing" do
      expect(summary("query_expanded", original_query: "trainers")).to eq("Query expanded - trainers")
    end

    it "humanises search completion result types" do
      expect(summary("search_completed", results_type: "fuzzy_search", result_count: 0)).to eq("Search completed - fuzzy search")
    end
  end

  describe "#search_diagnostic_event_details" do
    it "renders relevant fields as readable key value rows and keeps raw fields available" do
      html = details("search_completed", search_completed_fields)

      expect(html).to include(*search_completed_detail_fragments)
    end

    it "renders answer detail rows with commodity code and confidence" do
      html = details("answer_returned", answer_returned_fields)

      expect(html).to include(*answer_detail_fragments)
    end

    it "uses the goods nomenclature code as frontend link text in result tables" do
      page = Capybara.string(details("fuzzy_results_returned", fuzzy_results_fields))

      expect(page).to have_css("a.govuk-link[href='#{TradeTariffAdmin.frontend_host}/commodities/6110301000']", exact_text: "6110301000")
    end

    it "omits self-text and label columns from classic fuzzy result tables" do
      page = Capybara.string(details("fuzzy_results_returned", fuzzy_results_fields))

      expect(table_headings(page)).to eq(%w[Code Type Score])
    end

    it "keeps self-text and label columns in internal retrieval result tables" do
      page = Capybara.string(details("retrieval_results_returned", retrieval_results_fields))

      expect(table_headings(page)).to eq(%w[Code Type Score Self-text Labels])
    end

    it "links selected result details to the frontend goods nomenclature path" do
      page = Capybara.string(details("result_selected", selected_heading_fields))

      expect(page).to have_link("6110", href: "#{TradeTariffAdmin.frontend_host}/headings/6110")
    end
  end

  describe "#search_diagnostic_event_name" do
    it "humanises event names for display" do
      expect(helper.search_diagnostic_event_name(event: "query_expansion_decided")).to eq("Query expansion decided")
    end
  end

  describe "#search_diagnostic_search_type" do
    it "humanises search type values for display" do
      expect(search_type_labels).to eq("interactive" => "Internal", "classic" => "Classic")
    end
  end

  describe "#search_diagnostic_events_with_context" do
    it "applies the original search type to selected results when the event has no type" do
      contextual_events = helper.search_diagnostic_events_with_context(classic_selection_events)

      expect(contextual_events.pluck(:search_type)).to eq(%w[classic classic classic])
    end
  end

  describe "#search_diagnostic_overview" do
    it "summarises a selected fuzzy classic search for operator triage" do
      expect(overview_summary(classic_overview_events)).to eq(classic_overview_summary)
    end

    it "summarises a zero-result search as needing attention" do
      expect(overview_summary(zero_result_events)).to eq(zero_result_overview_summary)
    end
  end

  describe "#search_diagnostic_event_time" do
    it "shows compact time for timestamped events" do
      expect(helper.search_diagnostic_event_time(timestamp: "2026-06-05 09:58:58.123")).to eq("09:58:58.123")
    end

    it "falls back when the timestamp is absent" do
      expect(helper.search_diagnostic_event_time({})).to eq("-")
    end
  end

  describe "#search_diagnostic_time_range" do
    it "formats the range using GOV.UK date style with times" do
      diagnostic = SearchDiagnostic.new(start_time: "2026-06-05T09:55:00Z", end_time: "2026-06-05T10:00:00Z")

      expect(helper.search_diagnostic_time_range(diagnostic)).to eq("5 June 2026 at 09:55 to 5 June 2026 at 10:00")
    end
  end

  describe "#search_diagnostic_timeline_events" do
    it "positions events across the request duration and flags significant events" do
      expect(timeline_summary(timeline_events)).to eq(expected_timeline_summary)
    end

    it "spreads sub-second journeys by event order" do
      expect(timeline_summary(sub_second_timeline_events)).to eq(expected_sub_second_timeline_summary)
    end

    it "spreads longer journeys by event order rather than elapsed time" do
      expect(timeline_summary(uneven_timeline_events).pluck(1)).to eq([0, 25, 50, 75, 100])
    end
  end

  describe "#search_diagnostic_significant_timeline_events" do
    it "returns significant events when present" do
      timeline_events = helper.search_diagnostic_timeline_events(self.timeline_events)

      expect(helper.search_diagnostic_significant_timeline_events(timeline_events).pluck(:name)).to eq(["Answer returned", "Search failed"])
    end

    it "falls back to all events when no significant events were logged" do
      events = helper.search_diagnostic_timeline_events([{ timestamp: "2026-06-05 09:59:00.000", event: "search_started" }])

      expect(helper.search_diagnostic_significant_timeline_events(events).pluck(:name)).to eq(["Search started"])
    end
  end

  def summary(event_name, fields)
    helper.search_diagnostic_event_summary(event: event_name, fields: fields)
  end

  def details(event_name, fields)
    helper.search_diagnostic_event_details(event: event_name, fields: fields)
  end

  def table_headings(page)
    page.all("table.app-diagnostics-table:first-of-type th").map(&:text)
  end

  def query_preparation_summaries
    {
      "search_started" => summary("search_started", query: "red shoes", search_type: "interactive"),
      "query_expanded" => summary("query_expanded", original_query: "trainers", expanded_query: "athletic shoes", reason: "colloquial", duration_ms: 123.45),
      "query_refined" => summary("query_refined", original_query: "shoes", refined_query: "shoes leather", answer_count: 1),
      "query_expansion_decided" => summary("query_expansion_decided", query: "shoes", expand: true, reason: "low_results", result_count: 2, max_score: 4.5),
    }
  end

  def expected_query_preparation_summaries
    {
      "search_started" => "Search started - red shoes",
      "query_expanded" => "Query expanded - trainers to athletic shoes",
      "query_refined" => "Query refined - added 1 answer",
      "query_expansion_decided" => "Query expansion used - low results",
    }
  end

  def operational_summaries
    {
      "api_call_completed" => summary("api_call_completed", model: "gpt-4.1-mini", response_type: "questions", attempt_number: 2, duration_ms: 450.1),
      "description_intercept_checked" => summary("description_intercept_checked", matched: true, term: "gift", excluded: false, filtering: true),
      "retrieval_leg_completed" => summary("retrieval_leg_completed", leg: "vector", status: "success", result_count: 12, duration_ms: 50.4),
      "result_selected" => summary("result_selected", goods_nomenclature_item_id: "6403990000", goods_nomenclature_class: "Commodity"),
      "search_failed" => summary("search_failed", search_type: "interactive", error_type: "Faraday::TimeoutError"),
    }
  end

  def expected_operational_summaries
    {
      "api_call_completed" => "Model returned questions - attempt 2",
      "description_intercept_checked" => "Description intercept matched - gift",
      "retrieval_leg_completed" => "Vector retrieval succeeded - 12 results",
      "result_selected" => "Result selected - commodity 6403990000",
      "search_failed" => "Search failed - Faraday::TimeoutError",
    }
  end

  def search_completed_fields
    {
      search_type: "interactive",
      query: "red shoes",
      results_type: "hybrid",
      final_result_type: "answers",
      total_attempts: 2,
      total_questions: 1,
      result_count: 3,
      max_score: 12.3456,
      total_duration_ms: 1500.25,
      description_intercept_matched: true,
      description_intercept_term: "gift",
    }
  end

  def search_completed_detail_fragments
    [
      "Query",
      "red shoes",
      "Results type",
      "hybrid",
      "Final result",
      "answers",
      "Total attempts",
      "2",
      "Total questions",
      "1",
      "Result count",
      "3",
      "Max score",
      "12.3456",
      "Total duration",
      "1,500.25 ms",
      "Description intercept",
      "Matched gift",
      "View raw fields",
    ]
  end

  def answer_returned_fields
    {
      answer_count: 2,
      confidence_levels: { "strong" => 1, "possible" => 1 },
      attempt_number: 1,
      details: {
        answers: [
          { commodity_code: "6403990000", confidence: "strong" },
          { commodity_code: "4202210000", confidence: "possible" },
        ],
      },
    }
  end

  def answer_detail_fragments
    ["Attempt", "1", "Confidence levels", "strong: 1, possible: 1", "6403990000", "strong", "4202210000", "possible", "View labels"]
  end

  def fuzzy_results_fields
    {
      result_count: 1,
      details: {
        goods_nomenclature_match: {
          commodities: [
            {
              goods_nomenclature_item_id: "6110301000",
              goods_nomenclature_class: "Commodity",
              score: 8.09,
            },
          ],
        },
      },
    }
  end

  def retrieval_results_fields
    {
      retrieval_method: "hybrid",
      stage: "after_rrf",
      result_count: 1,
      details: {
        results: [
          {
            goods_nomenclature_item_id: "6110301000",
            goods_nomenclature_class: "Commodity",
            score: 8.09,
            self_text_id: 123,
          },
        ],
      },
    }
  end

  def selected_heading_fields
    {
      goods_nomenclature_item_id: "6110",
      goods_nomenclature_class: "Heading",
    }
  end

  def search_type_labels
    %w[interactive classic].index_with do |search_type|
      helper.search_diagnostic_search_type(search_type: search_type)
    end
  end

  def timeline_summary(events)
    helper.search_diagnostic_timeline_events(events).map do |event|
      [
        event[:name],
        event[:position],
        event[:significant],
        event[:search_type],
      ]
    end
  end

  def overview_summary(events)
    overview = helper.search_diagnostic_overview(events)

    {
      query: overview[:query],
      outcome_tags: overview[:outcome_tags].pluck(:label, :colour),
      route_tags: overview[:route_tags].pluck(:label, :colour),
      results: overview[:results],
      selected_results: overview[:selected_results],
    }
  end

  def classic_overview_summary
    {
      query: "jumper",
      outcome_tags: [["Result selected", "green"], ["Results returned", "green"]],
      route_tags: [%w[Classic blue], %w[Fuzzy purple]],
      results: "3 fuzzy results",
      selected_results: [
        { id: "6110", href: "#{TradeTariffAdmin.frontend_host}/headings/6110" },
        { id: "6110309900", href: "#{TradeTariffAdmin.frontend_host}/commodities/6110309900" },
      ],
    }
  end

  def zero_result_overview_summary
    {
      query: "women's breif",
      outcome_tags: [["Zero results", "yellow"]],
      route_tags: [%w[Classic blue], %w[Fuzzy purple]],
      results: "0 fuzzy results",
      selected_results: [],
    }
  end

  def timeline_events
    [
      { timestamp: "2026-06-05 09:59:02.000", event: "answer_returned", search_type: "interactive", fields: { answer_count: 1 } },
      { timestamp: "2026-06-05 09:59:00.000", event: "search_started", search_type: "interactive", fields: { query: "shoes" } },
      { timestamp: "2026-06-05 09:59:04.000", event: "search_failed", search_type: "interactive", fields: { error_type: "Faraday::TimeoutError" } },
    ]
  end

  def expected_timeline_summary
    [
      ["Search started", 0, false, "Internal"],
      ["Answer returned", 50, true, "Internal"],
      ["Search failed", 100, true, "Internal"],
    ]
  end

  def sub_second_timeline_events
    [
      { timestamp: "2026-06-05 09:59:02.537", event: "search_started", search_type: "classic", fields: { query: "shoes" } },
      { timestamp: "2026-06-05 09:59:02.598", event: "fuzzy_results_returned", search_type: "classic", fields: { result_count: 0 } },
      { timestamp: "2026-06-05 09:59:02.598", event: "search_completed", search_type: "classic", fields: { result_count: 0, results_type: "fuzzy_search" } },
    ]
  end

  def expected_sub_second_timeline_summary
    [
      ["Search started", 0, false, "Classic"],
      ["Fuzzy results returned", 50, true, "Classic"],
      ["Search completed", 100, true, "Classic"],
    ]
  end

  def uneven_timeline_events
    [
      { timestamp: "2026-06-05 09:33:44.114", event: "search_started", search_type: "classic", fields: { query: "jumper" } },
      { timestamp: "2026-06-05 09:33:44.114", event: "fuzzy_results_returned", search_type: "classic", fields: { result_count: 3 } },
      { timestamp: "2026-06-05 09:33:44.114", event: "search_completed", search_type: "classic", fields: { result_count: 3, results_type: "fuzzy_search" } },
      { timestamp: "2026-06-05 09:33:46.500", event: "result_selected", search_type: "classic", fields: { goods_nomenclature_item_id: "6110", goods_nomenclature_class: "Heading" } },
      { timestamp: "2026-06-05 09:33:52.000", event: "result_selected", search_type: "classic", fields: { goods_nomenclature_item_id: "6110309900", goods_nomenclature_class: "Commodity" } },
    ]
  end

  def classic_selection_events
    [
      { timestamp: "2026-06-05 09:59:00.000", event: "search_started", search_type: "classic", fields: { query: "jumper" } },
      { timestamp: "2026-06-05 09:59:02.000", event: "fuzzy_results_returned", search_type: "classic", fields: { result_count: 3 } },
      { timestamp: "2026-06-05 09:59:04.000", event: "result_selected", search_type: nil, fields: { goods_nomenclature_item_id: "6110", goods_nomenclature_class: "Heading" } },
    ]
  end

  def classic_overview_events
    [
      { timestamp: "2026-06-05 09:33:44.079", event: "search_started", search_type: "classic", fields: { query: "jumper" } },
      { timestamp: "2026-06-05 09:33:44.114", event: "fuzzy_results_returned", search_type: "classic", fields: { result_count: 3 } },
      { timestamp: "2026-06-05 09:33:44.114", event: "search_completed", search_type: "classic", fields: { query: "jumper", result_count: 3, results_type: "fuzzy_search" } },
      { timestamp: "2026-06-05 09:33:52.989", event: "result_selected", search_type: "classic", fields: { goods_nomenclature_item_id: "6110", goods_nomenclature_class: "Heading" } },
      { timestamp: "2026-06-05 09:34:03.893", event: "result_selected", search_type: "classic", fields: { goods_nomenclature_item_id: "6110309900", goods_nomenclature_class: "Commodity" } },
    ]
  end

  def zero_result_events
    [
      { timestamp: "2026-06-05 09:33:44.079", event: "search_started", search_type: "classic", fields: { query: "women's breif" } },
      { timestamp: "2026-06-05 09:33:44.114", event: "fuzzy_results_returned", search_type: "classic", fields: { result_count: 0 } },
      { timestamp: "2026-06-05 09:33:44.114", event: "search_completed", search_type: "classic", fields: { query: "women's breif", result_count: 0, results_type: "fuzzy_search" } },
    ]
  end
end
