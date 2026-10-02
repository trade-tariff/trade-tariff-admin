RSpec.describe EvaluationConfiguration do
  describe ".schema" do
    before do
      stub_api_request("/search/evaluation/configuration").and_return(
        status: 200,
        headers: { "content-type" => "application/json; charset=utf-8" },
        body: {
          baseline: { "max_rounds" => 7 },
          allowed_overrides: [{ name: "max_rounds", config_type: "integer", min: 1, max: 20 }],
        }.to_json,
      )
    end

    it "returns the baseline and the typed override schema" do
      schema = described_class.schema

      expect(schema).to eq(
        baseline: { "max_rounds" => 7 },
        allowed_overrides: [{ name: "max_rounds", config_type: "integer", min: 1, max: 20 }],
      )
    end
  end
end
