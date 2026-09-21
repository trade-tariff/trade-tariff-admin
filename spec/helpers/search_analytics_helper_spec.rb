RSpec.describe SearchAnalyticsHelper do
  describe "#search_analytics_query_collected?" do
    it "treats a missing queries map as collected so older payloads keep their widgets" do
      expect(helper.search_analytics_query_collected?({ complete: false }, :ai_cost_trend)).to be(true)
    end

    it "hides a widget when that query has no collected days" do
      coverage = { queries: { ai_cost_trend: { collected_days: 0 } } }
      expect(helper.search_analytics_query_collected?(coverage, :ai_cost_trend)).to be(false)
    end
  end

  describe "#search_analytics_number" do
    it "formats large numbers with delimiters" do
      expect(helper.search_analytics_number(12_400)).to eq("12,400")
    end
  end

  describe "#search_analytics_percentage" do
    it "formats rates as percentages" do
      expect(helper.search_analytics_percentage(0.084)).to eq("8.4%")
    end
  end

  describe "#search_analytics_share" do
    it "distinguishes small positive shares from zero", :aggregate_failures do
      expect(helper.search_analytics_share(0.00008)).to eq("<0.1%")
      expect(helper.search_analytics_share(0.001)).to eq("0.1%")
      expect(helper.search_analytics_share(0)).to eq("0%")
      expect(helper.search_analytics_share(0.999)).to eq("99.9%")
    end
  end

  describe "#search_analytics_latency" do
    it "preserves subsecond latency instead of displaying zero seconds", :aggregate_failures do
      expect(helper.search_analytics_latency(29.6)).to eq("29.6ms")
      expect(helper.search_analytics_latency(0)).to eq("0ms")
      expect(helper.search_analytics_latency(nil)).to eq("Unavailable")
    end

    it "formats millisecond latency as seconds" do
      expect(helper.search_analytics_latency(1_800)).to eq("1.8s")
    end
  end

  describe "#search_analytics_cost" do
    it "formats dollar amounts consistently to two decimal places", :aggregate_failures do
      expect(helper.search_analytics_cost(0.313641)).to eq("$0.31")
      expect(helper.search_analytics_cost(1)).to eq("$1.00")
      expect(helper.search_analytics_cost("1234.565")).to eq("$1,234.57")
      expect(helper.search_analytics_cost(0.01)).to eq("$0.01")
    end

    it "distinguishes subcent costs from zero and unavailable values", :aggregate_failures do
      expect(helper.search_analytics_cost(0.00150714)).to eq("<$0.01")
      expect(helper.search_analytics_cost("0.000025")).to eq("<$0.01")
      expect(helper.search_analytics_cost(0)).to eq("$0.00")
      expect(helper.search_analytics_cost(nil)).to eq("Unavailable")
    end
  end

  describe "#search_analytics_cost_chart_payload" do
    let(:payload) do
      helper.search_analytics_cost_chart_payload(
        [
          { bucket: "2026-06-10T09:00:00Z", input_cost_usd: 0.004, output_cost_usd: 0.006, embedding_cost_usd: 0.0002, total_cost_usd: 0.01020014 },
        ],
      )
    end
    let(:expected_datasets) do
      [
        include("label" => "Estimated AI cost", "data" => [0.01020014]),
      ]
    end

    it "plots the authoritative total without rounding the underlying values" do
      expect(JSON.parse(payload).fetch("datasets")).to match(expected_datasets)
    end
  end

  describe "#search_analytics_frontend_selection_rows" do
    it "labels missing rank and confidence without dropping the event" do
      expect(helper.search_analytics_frontend_selection_rows([{ event_count: 2 }])).to eq([["Unknown rank, Unknown", 2]])
    end
  end

  describe "#search_analytics_ai_model_rows" do
    it "formats missing and unknown model names and computes share" do
      rows = helper.search_analytics_ai_model_rows([{ model: "unknown", calls: 2, total_cost_usd: 0.002 }], total_cost: 0.01)
      expect(rows).to contain_exactly(label: "Unknown", calls: 2, total_cost_usd: 0.002, share: 0.2)
    end
  end

  describe "#search_analytics_ai_operation_rows" do
    it "adds readable labels and each operation's share of total cost" do
      rows = helper.search_analytics_ai_operation_rows(
        [{ event_kind: "vector_search_query_embedding", calls: 2, total_tokens: 100, total_cost_usd: 0.002 }],
        total_cost: 0.01,
      )

      expect(rows).to contain_exactly(label: "Search matching preparation", calls: 2, total_cost_usd: 0.002, share: 0.2)
    end
  end

  {
    "interactive_search" => "AI-assisted search",
    "interactive_search_final_answer" => "AI answer",
    "search_query_expansion" => "Search term expansion",
    "duplicate_question_guard" => "Duplicate question check",
    "unrecognised_operation" => "Unrecognised operation",
  }.each do |event_kind, label|
    it "labels #{event_kind} as #{label}" do
      rows = helper.search_analytics_ai_operation_rows([{ event_kind: }], total_cost: 0)
      expect(rows.first[:label]).to eq(label)
    end
  end

  describe "#search_analytics_chart_payload" do
    let(:trend_payload) do
      helper.search_analytics_chart_payload(
        [
          { bucket: "2026-06-09T00:00:00Z", all: 52, classic: 31 },
          { bucket: "2026-06-10T00:00:00Z", all: 48, classic: 29 },
        ],
        series: { all: "All", classic: "Classic" },
      )
    end

    let(:daily_payload) do
      helper.search_analytics_chart_payload(
        [
          { bucket: "2026-06-10T00:00:00Z", all: 52 },
        ],
        series: { all: "All" },
      )
    end

    let(:expected_trend_payload) do
      {
        "labels" => ["9 June 2026", "10 June 2026"],
        "datasets" => [
          include("label" => "All", "data" => [52, 48], "borderColor" => "#144e81", "backgroundColor" => "#144e81"),
          include("label" => "Classic", "data" => [31, 29], "borderColor" => "#005a30", "backgroundColor" => "#005a30"),
        ],
      }
    end

    let(:payload_with_zero_series) do
      helper.search_analytics_chart_payload(
        [
          { bucket: "2026-06-10T09:00:00Z", completed: 52, failed: "0" },
          { bucket: "2026-06-10T10:00:00Z", completed: 48, failed: "0" },
        ],
        series: { completed: "Completed", failed: "Failed" },
      )
    end

    let(:payload_with_negligible_series) do
      helper.search_analytics_chart_payload(
        [
          { bucket: "2026-06-10T09:00:00Z", all: 140_000, classic: 139_990, internal: 10 },
          { bucket: "2026-06-10T10:00:00Z", all: 140_000, classic: 139_990, internal: 10 },
        ],
        series: { all: "All", classic: "Classic", internal: "Internal" },
        minimum_series_share: 1,
      )
    end

    it "builds chart JSON from trend rows" do
      expect(JSON.parse(trend_payload)).to match(expected_trend_payload)
    end

    it "preserves all 24 hourly points and formats their intervals", :aggregate_failures do
      rows = (0..23).map { |hour| { bucket: Time.utc(2026, 9, 5, hour).iso8601, all: hour + 1 } }
      payload = JSON.parse(helper.search_analytics_chart_payload(rows, series: { all: "All" }, bucket_size: "hour"))
      expect(payload.fetch("datasets").first.fetch("data")).to eq((1..24).to_a)
      expect(payload.fetch("labels").size).to eq(24)
      expect(payload.fetch("labels").values_at(0, 11, 23)).to eq(["midnight to 1am", "11am to midday", "11pm to midnight"])
    end

    it "labels daily buckets as dates" do
      expect(JSON.parse(daily_payload).fetch("labels")).to eq(["10 June 2026"])
    end

    it "omits chart series that are zero for every bucket" do
      expect(JSON.parse(payload_with_zero_series).fetch("datasets").pluck("label")).to eq(%w[Completed])
    end

    it "omits chart series below the configured share of the largest series" do
      expect(JSON.parse(payload_with_negligible_series).fetch("datasets").pluck("label")).to eq(%w[All Classic])
    end
  end

  describe "#search_analytics_bucket_date" do
    it "uses a plain date for daily bins" do
      expect(helper.search_analytics_bucket_date("2026-09-05T00:00:00Z", bucket_size: "day")).to eq("5 September 2026")
    end

    it "identifies hourly intervals without changing their date" do
      expect(helper.search_analytics_bucket_date("2026-09-05T09:00:00Z", bucket_size: "hour")).to eq("5 September 2026, 9am to 10am")
    end
  end

  describe "#search_analytics_date" do
    it "presents whole reporting days without times", :aggregate_failures do
      expect(helper.search_analytics_date("2026-09-05T00:00:00Z")).to eq("5 September 2026")
      expect(helper.search_analytics_date("2026-09-05T17:30:00Z")).to eq("5 September 2026")
    end

    it "keeps reporting dates in UTC even when the application uses another timezone" do
      Time.use_zone("Pacific/Auckland") do
        expect(helper.search_analytics_date("2026-09-05T23:00:00Z")).to eq("5 September 2026")
      end
    end
  end
end
