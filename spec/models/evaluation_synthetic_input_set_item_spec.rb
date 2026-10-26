RSpec.describe EvaluationSyntheticInputSetItem do
  subject(:item) { described_class.new(attributes) }

  let(:attributes) do
    {
      "resource_id" => "5",
      "synthetic_input_set_id" => 3,
      "synthetic_atar_id" => 42,
      "query" => "Reusable plastic food storage box with a clip-on lid.",
      "expected_code" => "3924100000",
    }
  end

  it "puts the set in the collection path" do
    expect(item.collection_path).to eq("admin/search/evaluation/synthetic_input_sets/3/items")
  end

  it "carries what the backend froze into the set" do
    expect(item).to have_attributes(synthetic_atar_id: 42, query: "Reusable plastic food storage box with a clip-on lid.", expected_code: "3924100000")
  end
end
