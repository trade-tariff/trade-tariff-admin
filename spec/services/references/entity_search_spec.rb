RSpec.describe References::EntitySearch do
  describe ".call" do
    let(:section) { build(:section, resource_id: 1, numeral: "I", title: "Live animals") }
    let(:internal_search_url) { "#{TradeTariffAdmin::ServiceChooser.service_choices.fetch('uk')}/internal/search" }
    let(:search_data) do
      [
        {
          type: "chapter",
          attributes: {
            goods_nomenclature_item_id: "0100000000",
            description: "Live animals",
          },
        },
        {
          type: "heading",
          attributes: {
            goods_nomenclature_item_id: "0101000000",
            description: "Live horses",
          },
        },
        {
          type: "subheading",
          attributes: {
            goods_nomenclature_item_id: "0101210000",
            description: "Pure-bred breeding animals",
          },
        },
        {
          type: "commodity",
          attributes: {
            goods_nomenclature_item_id: "0101210000",
            producline_suffix: "80",
            description: "Pure-bred breeding animals",
          },
        },
      ]
    end

    before do
      allow(Section).to receive(:all).and_return([section])
    end

    context "with matching search results" do
      let(:expected_paths) do
        [
          references_section_chapters_path(section),
          references_chapter_search_references_path("01"),
          references_heading_search_references_path("0101"),
          references_commodity_search_references_path("0101210000-80"),
        ]
      end

      before do
        stub_request(:post, internal_search_url).to_return(api_success_response(data: search_data))
      end

      it "maps and de-duplicates searchable entities", :aggregate_failures do
        results = described_class.call(query: "live")

        expect(results.map(&:entity_type)).to include("Section", "Chapter", "Heading", "Commodity")
        expect(results.count { |result| result.entity_type == "Heading" && result.code == "0101" }).to eq(1)
        expect(results.map(&:path)).to include(*expected_paths)
      end
    end

    it "returns no results for a blank query without calling the API" do
      described_class.call(query: " ")

      expect(WebMock).not_to have_requested(:post, internal_search_url)
    end
  end
end
