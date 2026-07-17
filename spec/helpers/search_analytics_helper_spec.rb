RSpec.describe SearchAnalyticsHelper do
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

  describe "#search_analytics_latency" do
    it "formats millisecond latency as seconds" do
      expect(helper.search_analytics_latency(1_800)).to eq("1.8s")
    end
  end

  describe "#search_analytics_cost" do
    it "formats small dollar costs without hiding useful precision", :aggregate_failures do
      expect(helper.search_analytics_cost(0.00150714)).to eq("US$0.001507")
      expect(helper.search_analytics_cost(0.01)).to eq("US$0.01")
    end
  end

  describe "#search_analytics_cost_chart_payload" do
    let(:payload) do
      helper.search_analytics_cost_chart_payload(
        [
          { bucket: "2026-06-10T09:00:00Z", input_cost_usd: 0.004, output_cost_usd: 0.006, embedding_cost_usd: 0.0002 },
        ],
      )
    end
    let(:expected_datasets) do
      [
        include("label" => "Model input", "data" => [0.004]),
        include("label" => "Model output", "data" => [0.006]),
        include("label" => "Embeddings", "data" => [0.0002]),
      ]
    end

    it "preserves fractional costs and labels each cost component" do
      expect(JSON.parse(payload).fetch("datasets")).to match(expected_datasets)
    end
  end

  describe "#search_analytics_ai_operation_rows" do
    it "adds readable labels and each operation's share of total cost" do
      rows = helper.search_analytics_ai_operation_rows(
        [{ event_kind: "vector_search_query_embedding", calls: 2, total_tokens: 100, total_cost_usd: 0.002 }],
        total_cost: 0.01,
      )

      expect(rows).to contain_exactly(include(label: "Vector query embedding", calls: 2, total_tokens: 100, share: 0.2))
    end
  end

  describe "#search_analytics_chart_payload" do
    let(:trend_payload) do
      helper.search_analytics_chart_payload(
        [
          { bucket: "2026-06-10T09:00:00Z", all: 52, classic: 31 },
          { bucket: "2026-06-10T10:00:00Z", all: 48, classic: 29 },
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
        "labels" => ["09:00", "10:00"],
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

    it "labels daily buckets as dates" do
      expect(JSON.parse(daily_payload).fetch("labels")).to eq(["10 Jun"])
    end

    it "omits chart series that are zero for every bucket" do
      expect(JSON.parse(payload_with_zero_series).fetch("datasets").pluck("label")).to eq(%w[Completed])
    end

    it "omits chart series below the configured share of the largest series" do
      expect(JSON.parse(payload_with_negligible_series).fetch("datasets").pluck("label")).to eq(%w[All Classic])
    end
  end

  describe "#search_analytics_view_summary_rows" do
    let(:rows) do
      helper.search_analytics_view_summary_rows(
        {
          classic: { searches: 710 },
          internal: { searches: 530 },
        },
      )
    end

    it "builds proportional rows for the comparison summary" do
      expect(rows).to contain_exactly(
        include(label: "Classic", searches: 710, percentage: "57.3%", width: 57.3),
        include(label: "Internal", searches: 530, percentage: "42.7%", width: 42.7),
      )
    end
  end

  describe "#search_analytics_request_source_rows" do
    let(:rows) do
      helper.search_analytics_request_source_rows(
        {
          frontend: { searches: 920, failure_rate: 0.01, zero_result_rate: 0.08, selection_rate: 0.41, p90_latency_ms: 1800 },
          backend_only: { searches: 320, failure_rate: 0.02, zero_result_rate: 0.09, selection_rate: 0.35, p90_latency_ms: 900 },
          unknown: { searches: 5, failure_rate: 0.0, zero_result_rate: 0.2, selection_rate: 0.2, p90_latency_ms: 700 },
          partner_api: { searches: 12, failure_rate: 0.0, zero_result_rate: 0.1, selection_rate: 0.3, p90_latency_ms: 600 },
        },
      )
    end
    let(:expected_rows) do
      [
        include(key: "frontend", label: "Frontend-routed", searches: 920),
        include(key: "backend_only", label: "Direct backend / non-frontend", searches: 320),
        include(key: "unknown", label: "Unknown", searches: 5),
        include(key: "partner_api", label: "Partner api", searches: 12),
      ]
    end

    it "builds ordered rows for known and unexpected request sources" do
      expect(rows).to match(expected_rows)
    end
  end

  describe "#search_analytics_show_view_summary?" do
    subject(:show_view_summary) { helper.search_analytics_show_view_summary?(comparisons) }

    context "when internal searches have meaningful volume" do
      let(:comparisons) do
        {
          classic: { searches: 9_900 },
          internal: { searches: 100 },
        }
      end

      it "shows the summary" do
        expect(show_view_summary).to be(true)
      end
    end

    context "when internal searches are negligible" do
      let(:comparisons) do
        {
          classic: { searches: 131_468 },
          internal: { searches: 0 },
        }
      end

      it "hides the summary" do
        expect(show_view_summary).to be(false)
      end
    end
  end

  describe "#search_analytics_timestamp" do
    it "formats ISO timestamps for the dashboard" do
      expect(helper.search_analytics_timestamp("2026-06-10T09:55:00Z")).to eq("10 June 2026 at 09:55")
    end
  end
end
