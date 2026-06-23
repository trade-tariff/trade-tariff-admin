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
