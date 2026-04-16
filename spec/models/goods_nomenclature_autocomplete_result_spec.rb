# rubocop:disable RSpec/ExampleLength
RSpec.describe GoodsNomenclatureAutocompleteResult do
  subject(:result) { described_class.new(attributes) }

  let(:attributes) do
    {
      resource_id: "120190",
      goods_nomenclature_item_id: "1201900000",
      description: "Soya bean flour and meal, whether or not defatted",
    }
  end

  describe "#label" do
    it "combines the code and truncated description" do
      expect(result.label).to eq("1201900000 - Soya bean flour and meal, whether or not defatted")
    end
  end

  describe "#truncated_description" do
    let(:attributes) do
      super().merge(description: "A" * 120)
    end

    it "truncates long descriptions" do
      expect(result.truncated_description.length).to be <= 100
    end
  end

  describe ".listing" do
    let(:response) do
      {
        status: 200,
        headers: { "content-type" => "application/json; charset=utf-8" },
        body: {
          data: [
            {
              type: "goods_nomenclature_autocomplete",
              id: "120190",
              attributes: attributes,
            },
          ],
        }.to_json,
      }
    end

    before do
      stub_api_request("/goods_nomenclature_autocomplete")
        .with(query: hash_including("q" => "1201", "filter" => hash_including("goods_nomenclature_class" => %w[Chapter Heading])))
        .and_return(response)
    end

    it "returns the proxy listing data" do
      expect(described_class.listing("1201", filters: { goods_nomenclature_class: %w[Chapter Heading] })).to eq([
        {
          id: "120190",
          goods_nomenclature_item_id: "1201900000",
          description: "Soya bean flour and meal, whether or not defatted",
          truncated_description: "Soya bean flour and meal, whether or not defatted",
          label: "1201900000 - Soya bean flour and meal, whether or not defatted",
        },
      ])
    end
  end
end

# rubocop:enable RSpec/ExampleLength
