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
end
