RSpec.describe EvaluationRunsHelper do
  describe "#evaluation_run_eta" do
    let(:run) { EvaluationRun.new(resource_id: "9", result_count: 4, started_at: 2.minutes.ago.iso8601) }

    it "estimates the remaining time from throughput so far" do
      expect(helper.evaluation_run_eta(run, 8)).to match(/\AAbout \d+ minutes? remaining\z/)
    end

    it "is nil when fewer than 3 items have finished" do
      run = EvaluationRun.new(resource_id: "9", result_count: 2, started_at: 2.minutes.ago.iso8601)

      expect(helper.evaluation_run_eta(run, 8)).to be_nil
    end

    it "is nil when the run has already finished everything there was to do" do
      run = EvaluationRun.new(resource_id: "9", result_count: 8, started_at: 2.minutes.ago.iso8601)

      expect(helper.evaluation_run_eta(run, 8)).to be_nil
    end

    it "is nil when started_at is missing" do
      run = EvaluationRun.new(resource_id: "9", result_count: 4, started_at: nil)

      expect(helper.evaluation_run_eta(run, 8)).to be_nil
    end

    it "is nil rather than raising when started_at is unparseable" do
      run = EvaluationRun.new(resource_id: "9", result_count: 4, started_at: "not-a-date")

      expect(helper.evaluation_run_eta(run, 8)).to be_nil
    end
  end

  describe "#evaluation_run_running_a_while?" do
    it "is true once the run has been going longer than the threshold" do
      run = EvaluationRun.new(resource_id: "9", started_at: 10.minutes.ago.iso8601)

      expect(helper.evaluation_run_running_a_while?(run)).to be(true)
    end

    it "is false for a run that only just started" do
      run = EvaluationRun.new(resource_id: "9", started_at: 10.seconds.ago.iso8601)

      expect(helper.evaluation_run_running_a_while?(run)).to be(false)
    end

    it "is false when started_at is missing" do
      run = EvaluationRun.new(resource_id: "9", started_at: nil)

      expect(helper.evaluation_run_running_a_while?(run)).to be(false)
    end
  end

  describe "#evaluation_run_comparison_rows" do
    let(:run_a) do
      EvaluationRun.new(
        resource_id: "9", gold_in_top1_count: 6, gold_in_top5_count: 9, result_count: 10,
        total_cost_usd: "0.05", total_latency_seconds: 25.0
      )
    end
    let(:run_b) do
      EvaluationRun.new(
        resource_id: "10", gold_in_top1_count: 8, gold_in_top5_count: 10, result_count: 10,
        total_cost_usd: "0.08", total_latency_seconds: 40.0
      )
    end

    it "lists top1 accuracy, top5 accuracy, total cost and average latency, each compared independently" do
      rows = helper.evaluation_run_comparison_rows(run_a, run_b)

      expect(rows.map { |row| row[:label] }).to eq(["Top 1 accuracy", "Top 5 accuracy", "Total cost", "Average latency"])
    end

    it "says which run is better on a rate metric where a higher value wins" do
      rows = helper.evaluation_run_comparison_rows(run_a, run_b)
      top1_row = rows.find { |row| row[:label] == "Top 1 accuracy" }

      expect(top1_row).to include(value_a: "60%", value_b: "80%", better: "Run #10")
    end

    it "says which run is better on cost, where a lower value wins" do
      rows = helper.evaluation_run_comparison_rows(run_a, run_b)
      cost_row = rows.find { |row| row[:label] == "Total cost" }

      expect(cost_row).to include(value_a: "$0.0500", value_b: "$0.0800", better: "Run #9")
    end

    it "says which run is better on latency, where a lower value wins" do
      rows = helper.evaluation_run_comparison_rows(run_a, run_b)
      latency_row = rows.find { |row| row[:label] == "Average latency" }

      expect(latency_row).to include(value_a: "2.5s", value_b: "4.0s", better: "Run #9")
    end

    it "calls it a tie when both runs have the exact same value" do
      run_b = EvaluationRun.new(resource_id: "10", gold_in_top1_count: 6, gold_in_top5_count: 9, result_count: 10, total_cost_usd: "0.05", total_latency_seconds: 25.0)

      rows = helper.evaluation_run_comparison_rows(run_a, run_b)

      expect(rows).to all(include(better: "No change"))
    end

    it "says data isn't available rather than calling it a tie when either run has no data for a metric" do
      run_b = EvaluationRun.new(resource_id: "10", gold_in_top1_count: nil, gold_in_top5_count: nil, result_count: 0, total_cost_usd: nil, total_latency_seconds: nil)

      rows = helper.evaluation_run_comparison_rows(run_a, run_b)

      expect(rows).to all(include(better: "Not available"))
    end
  end
end
