RSpec.describe EvaluationGoldQueryItem do
  subject(:item) { described_class.new(attributes) }

  let(:attributes) do
    {
      "resource_id" => "synthetic_atar-12",
      "gold_query_set_id" => 3,
      "source_type" => "synthetic_atar",
      "source_id" => "12",
      "real_user_search" => "a made up search",
      "expected_code" => "6302100000",
      "emu_generic_query" => "sheets",
    }
  end

  describe "paths" do
    it "puts the set in the collection path" do
      expect(item.collection_path).to eq("admin/search/evaluation/gold_query_sets/3/items")
    end

    it "puts the set and the item in the singular path" do
      expect(item.singular_path).to eq("admin/search/evaluation/gold_query_sets/3/items/synthetic_atar-12")
    end
  end

  describe ".find_in_set" do
    before do
      stub_api_request("/search/evaluation/gold_query_sets/3/items/synthetic_atar-12")
        .and_return(jsonapi_response("gold_query_set_item", attributes))
    end

    it "reads the item from its set, without adding the set id to the query string" do
      found = described_class.find_in_set(3, "synthetic_atar-12")

      expect(found).to have_attributes(expected_code: "6302100000", to_param: "synthetic_atar-12")
    end
  end

  describe "#synthetic_atar?" do
    it { is_expected.to be_synthetic_atar }

    it "is false for an ATaR" do
      item.source_type = "atar"

      expect(item).not_to be_synthetic_atar
    end
  end

  describe "PERSONAS" do
    it "labels the three personas the generator writes, in order" do
      expect(described_class::PERSONAS.keys).to eq(%w[emu_generic emu_ordinary emu_specific])
    end

    it "has a query and a notes attribute for each persona" do
      expect(item).to respond_to(:emu_specific_query, :emu_specific_notes, :emu_ordinary_query=, :emu_generic_notes=)
    end
  end

  describe "#versions" do
    let(:versions_response) do
      jsonapi_response(
        "version",
        [{ "resource_id" => "31", "item_type" => "EvaluationGoldQuery", "item_id" => "5", "event" => "update", "object" => { "persona" => "emu_generic" } }],
      )
    end

    before do
      stub_api_request("/search/evaluation/gold_query_sets/3/items/synthetic_atar-12/versions").and_return(versions_response)
    end

    it "reads the history of the item's three rows from the backend" do
      expect(item.versions).to contain_exactly(
        an_instance_of(Version).and(have_attributes(object: include("persona" => "emu_generic"))),
      )
    end
  end
end
