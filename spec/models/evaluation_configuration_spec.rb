RSpec.describe EvaluationConfiguration do
  describe ".schema" do
    let(:search_index) { nil }

    before do
      body = {
        baseline: { "max_rounds" => 7 },
        allowed_overrides: [{ name: "max_rounds", config_type: "integer", min: 1, max: 20 }],
      }
      body[:search_index] = search_index if search_index

      stub_api_request("/search/evaluation/configuration").and_return(
        status: 200,
        headers: { "content-type" => "application/json; charset=utf-8" },
        body: body.to_json,
      )
    end

    it "returns the baseline and the typed override schema" do
      schema = described_class.schema

      expect(schema).to include(
        baseline: { "max_rounds" => 7 },
        allowed_overrides: [{ name: "max_rounds", config_type: "integer", min: 1, max: 20 }],
      )
    end

    context "when the backend reports on the search index" do
      let(:search_index) { { atar_keyword_count: 4512 } }

      it "returns what it says, with string keys like the baseline" do
        expect(described_class.schema[:search_index]).to eq("atar_keyword_count" => 4512)
      end
    end

    context "when the backend could not count the ATaR keywords" do
      let(:search_index) { { atar_keyword_count: nil } }

      it "keeps the report, with a nil count" do
        expect(described_class.schema[:search_index]).to eq("atar_keyword_count" => nil)
      end
    end

    context "when an older backend sends no search index report at all" do
      it "returns nil for it, which is not the same as a count that could not be made" do
        expect(described_class.schema[:search_index]).to be_nil
      end
    end
  end
end
