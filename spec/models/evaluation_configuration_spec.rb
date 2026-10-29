RSpec.describe EvaluationConfiguration do
  describe ".schema" do
    let(:body) do
      {
        baseline: { "max_rounds" => 7 },
        allowed_overrides: [{ name: "max_rounds", config_type: "integer", min: 1, max: 20 }],
      }
    end

    before do
      stub_api_request("/search/evaluation/configuration").and_return(
        status: 200,
        headers: { "content-type" => "application/json; charset=utf-8" },
        body: body.to_json,
      )
    end

    it "returns the baseline and the typed override schema" do
      schema = described_class.schema

      expect(schema).to eq(
        baseline: { "max_rounds" => 7 },
        allowed_overrides: [{ name: "max_rounds", config_type: "integer", min: 1, max: 20 }],
      )
    end

    # AI-1498 first added a count of the ATaR keywords in the search index to this response, then dropped it
    # in review. If a backend that still sends it is deployed, the form must not start showing it.
    context "when a backend still sends a search index report" do
      let(:body) { super().merge(search_index: { atar_keyword_count: 4512 }) }

      it "leaves it out" do
        expect(described_class.schema.keys).to contain_exactly(:baseline, :allowed_overrides)
      end
    end
  end
end
