RSpec.describe EvaluationGoldQuerySet do
  subject(:gold_query_set) { described_class.new(attributes) }

  let(:attributes) do
    {
      "resource_id" => "3",
      "name" => "Baseline",
      "status" => "generating",
      "requested_size" => 12,
      "planned_count" => 10,
      "generated_count" => 6,
      "failed_count" => 1,
      "atar_percentage" => 60,
      "atar_count" => 4,
      "synthetic_atar_count" => 2,
      "gold_query_count" => 18,
      "created_by" => "user-123",
      "failures" => [{ "source_type" => "atar", "source_id" => "600000001", "error" => "the model did not return acceptable phrases after 3 attempts" }],
    }
  end

  describe "#generating?" do
    it { is_expected.to be_generating }

    it "is false once the backend has finished" do
      gold_query_set.status = "ready"

      expect(gold_query_set).not_to be_generating
    end
  end

  describe "#finished_count" do
    it "adds the items that produced queries to the items that failed" do
      expect(gold_query_set.finished_count).to eq(7)
    end
  end

  describe "#item_count" do
    it "adds both source types" do
      expect(gold_query_set.item_count).to eq(6)
    end
  end

  describe "#gold_query_count" do
    it "exposes the backend's own total, one gold query per persona per item" do
      expect(gold_query_set.gold_query_count).to eq(18)
    end
  end

  describe "#synthetic_atar_percentage" do
    it "is what is left after the ATaR share" do
      expect(gold_query_set.synthetic_atar_percentage).to eq(40)
    end
  end

  describe "#failure_list" do
    it "gives the failed items" do
      expect(gold_query_set.failure_list.first).to include("source_id" => "600000001")
    end

    it "is empty when the backend sent none" do
      gold_query_set.failures = nil

      expect(gold_query_set.failure_list).to eq([])
    end
  end

  describe "#created_by_name" do
    it "shows the name of a known user" do
      create(:user, uid: "user-123", name: "Alex Example")

      expect(gold_query_set.created_by_name).to eq("Alex Example")
    end

    it "falls back to the stored value for an unknown user" do
      expect(gold_query_set.created_by_name).to eq("user-123")
    end

    it "is a dash when nothing was stored" do
      gold_query_set.created_by = nil

      expect(gold_query_set.created_by_name).to eq("-")
    end
  end

  describe "#singular_path" do
    it "points at the set once it is saved" do
      expect(gold_query_set.singular_path).to eq("admin/search/evaluation/gold_query_sets/3")
    end

    it "points at the collection while the set is new, because there is no id yet" do
      expect(described_class.new(name: "New").singular_path).to eq("admin/search/evaluation/gold_query_sets")
    end
  end

  describe ".conflict_detail" do
    it "reads the reason from the backend's error body" do
      error = Faraday::ConflictError.new("conflict", { status: 409, body: { "errors" => [{ "detail" => "These experiments use it: baseline." }] } })

      expect(described_class.conflict_detail(error)).to eq("These experiments use it: baseline.")
    end

    it "is nil when the body has no reason" do
      error = Faraday::ConflictError.new("conflict", { status: 409, body: "" })

      expect(described_class.conflict_detail(error)).to be_nil
    end
  end
end
