RSpec.describe EvaluationResult do
  subject(:result) { described_class.new(attributes) }

  let(:attributes) do
    {
      "resource_id" => "55",
      "run_id" => 9,
      "source_type" => "atar",
      "source_id" => "600004365",
      "persona" => "emu_generic",
      "expected_code" => "6404199000",
      "final_code" => "6404199000",
      "final_rank" => 1,
      "gold_in_top1" => true,
      "gold_in_top5" => true,
      "trace" => { "question_trace" => [{ "round" => 1, "question" => "What material?", "chosen" => "Rubber" }] },
    }
  end

  describe "paths" do
    it "puts the run in the collection path" do
      expect(result.collection_path).to eq("admin/search/evaluation/results")
    end
  end

  describe "#question_trace" do
    it "returns the recorded rounds" do
      expect(result.question_trace).to eq([{ "round" => 1, "question" => "What material?", "chosen" => "Rubber" }])
    end

    it "is empty, not nil, when nothing was recorded" do
      result.trace = {}

      expect(result.question_trace).to eq([])
    end
  end

  describe "#passed?" do
    it { is_expected.to be_passed }

    it "is false when the gold code was not in the top 5" do
      result.gold_in_top5 = false

      expect(result).not_to be_passed
    end
  end

  describe "#outcome" do
    it "is pass when the gold code was in the top 5" do
      expect(result.outcome).to eq("pass")
    end

    it "is fail when the gold code was not in the top 5 and nothing errored" do
      result.gold_in_top5 = false

      expect(result.outcome).to eq("fail")
    end

    it "is error when the gold query's own session broke, even though gold_in_top5 is also false" do
      result.gold_in_top5 = false
      result.error = "simulator exhausted its retries without producing an answer"

      expect(result.outcome).to eq("error")
    end
  end
end
