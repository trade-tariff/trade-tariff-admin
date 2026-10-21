RSpec.describe EvaluationSyntheticInputSet do
  subject(:synthetic_input_set) { described_class.new(attributes) }

  let(:attributes) do
    {
      "resource_id" => "3",
      "name" => "Baseline",
      "requested_size" => 10,
      "actual_size" => 8,
      "created_by" => "user-123",
      "items" => [{ "id" => "1", "synthetic_atar_id" => 42, "query" => "plastic box", "expected_code" => "3924100000" }],
    }
  end

  describe "#created_by_name" do
    it "shows the name of a known user" do
      create(:user, uid: "user-123", name: "Alex Example")

      expect(synthetic_input_set.created_by_name).to eq("Alex Example")
    end

    it "falls back to the stored value for an unknown user" do
      expect(synthetic_input_set.created_by_name).to eq("user-123")
    end

    it "is a dash when nothing was stored" do
      synthetic_input_set.created_by = nil

      expect(synthetic_input_set.created_by_name).to eq("-")
    end
  end

  describe "#singular_path" do
    it "points at the set once it is saved" do
      expect(synthetic_input_set.singular_path).to eq("admin/search/evaluation/synthetic_input_sets/3")
    end

    it "points at the collection while the set is new, because there is no id yet" do
      expect(described_class.new(name: "New").singular_path).to eq("admin/search/evaluation/synthetic_input_sets")
    end
  end

  it "carries the items the backend built the set from" do
    expect(synthetic_input_set.items).to contain_exactly(
      include("synthetic_atar_id" => 42, "query" => "plastic box", "expected_code" => "3924100000"),
    )
  end
end
