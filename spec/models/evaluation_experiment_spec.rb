RSpec.describe EvaluationExperiment do
  subject(:experiment) { described_class.new(attributes) }

  let(:attributes) do
    {
      "resource_id" => "7",
      "name" => "Baseline",
      "description" => "No overrides",
      "configuration_overrides" => {},
      "gold_query_set_id" => 3,
      "created_by" => "user-123",
    }
  end

  describe "#overridden?" do
    it "is false when there are no overrides" do
      expect(experiment).not_to be_overridden
    end

    it "is true when there is at least one override" do
      experiment.configuration_overrides = { "max_rounds" => 3 }

      expect(experiment).to be_overridden
    end
  end

  describe "#created_by_name" do
    it "shows the name of a known user" do
      create(:user, uid: "user-123", name: "Alex Example")

      expect(experiment.created_by_name).to eq("Alex Example")
    end

    it "falls back to the stored value for an unknown user" do
      expect(experiment.created_by_name).to eq("user-123")
    end
  end
end
