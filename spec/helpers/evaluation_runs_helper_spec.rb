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

  describe "#evaluation_run_display_name" do
    it "is just the bare run id when the run has no label yet (AI-1437)" do
      run = EvaluationRun.new(resource_id: "9", label: nil)

      expect(helper.evaluation_run_display_name(run)).to eq("Run #9")
    end

    it "appends the label once it exists" do
      run = EvaluationRun.new(resource_id: "9", label: "vector based retrieval")

      expect(helper.evaluation_run_display_name(run)).to eq("Run #9 — vector based retrieval")
    end
  end

  describe "#evaluation_run_label_suffix" do
    it "is blank when the run has no label yet" do
      run = EvaluationRun.new(resource_id: "9", label: nil)

      expect(helper.evaluation_run_label_suffix(run)).to eq("")
    end

    it "is the label with a leading em dash once it exists" do
      run = EvaluationRun.new(resource_id: "9", label: "vector based retrieval")

      expect(helper.evaluation_run_label_suffix(run)).to eq(" — vector based retrieval")
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

    it "names the winner by its label, not just its bare id, once one exists (AI-1437)" do
      run_b = EvaluationRun.new(resource_id: "10", label: "vector based retrieval", gold_in_top1_count: 8, result_count: 10)

      rows = helper.evaluation_run_comparison_rows(run_a, run_b)
      top1_row = rows.find { |row| row[:label] == "Top 1 accuracy" }

      expect(top1_row[:better]).to eq("Run #10 — vector based retrieval")
    end
  end

  describe "#evaluation_run_comparison_status_tag" do
    it "is blank for a completed run, since that's the normal case needing no flag" do
      run = EvaluationRun.new(resource_id: "9", status: "completed")

      expect(helper.evaluation_run_comparison_status_tag(run)).to eq("")
    end

    it "shows the status as a GOV.UK tag for a partially_failed run, so its results aren't mistaken for a completed run's" do
      run = EvaluationRun.new(resource_id: "9", status: "partially_failed")

      tag = Capybara.string(helper.evaluation_run_comparison_status_tag(run))
      expect(tag).to have_css("span.govuk-tag", text: "Partially failed")
    end
  end

  describe "#evaluation_override_hint" do
    let(:atars_entry) { { name: "search_atars_enabled", description: "Also search ATaR keywords." } }

    it "adds the live setting to any override, as On or Off for a yes/no one" do
      entry = { name: "search_non_declarables", description: "Include non-declarable codes." }

      expect(helper.evaluation_override_hint(entry, baseline: { "search_non_declarables" => true })).to eq("Include non-declarable codes. Live setting right now: On.")
    end

    it "shows a number as it is" do
      entry = { name: "max_rounds", description: "Most questions." }

      expect(helper.evaluation_override_hint(entry, baseline: { "max_rounds" => 7 })).to eq("Most questions. Live setting right now: 7.")
    end

    it "shows a choice as it is" do
      entry = { name: "question_model", description: "The AI model." }

      expect(helper.evaluation_override_hint(entry, baseline: { "question_model" => "gpt-5.4" })).to eq("The AI model. Live setting right now: gpt-5.4.")
    end

    it "puts extra detail between the description and the live setting" do
      entry = { name: "max_rounds", description: "Most questions." }

      expect(helper.evaluation_override_hint(entry, baseline: { "max_rounds" => 7 }, detail: "Between 1 and 20.")).to eq("Most questions. Between 1 and 20. Live setting right now: 7.")
    end

    it "is just the description for an override the baseline has no value for, such as simulator_model" do
      entry = { name: "simulator_model", description: "The simulated user." }

      expect(helper.evaluation_override_hint(entry, baseline: { "max_rounds" => 7 })).to eq("The simulated user.")
    end

    it "is just the description when the baseline value is nil, as reasoning_effort is for a model with none" do
      entry = { name: "reasoning_effort", description: "How hard it thinks." }

      expect(helper.evaluation_override_hint(entry, baseline: { "reasoning_effort" => nil })).to eq("How hard it thinks.")
    end

    it "treats search_atars_enabled like any other override" do
      expect(helper.evaluation_override_hint(atars_entry, baseline: { "search_atars_enabled" => true })).to eq("Also search ATaR keywords. Live setting right now: On.")
    end

    it "leaves out the live setting when the baseline does not hold one, instead of guessing Off" do
      expect(helper.evaluation_override_hint(atars_entry, baseline: {})).to eq("Also search ATaR keywords.")
    end

    it "copes with no baseline at all" do
      expect(helper.evaluation_override_hint(atars_entry, baseline: nil)).to eq("Also search ATaR keywords.")
    end
  end
end
