RSpec.describe TariffKnowledgeCompressedNote do
  subject(:compressed_note) { described_class.new(attributes) }

  let(:attributes) do
    {
      goods_nomenclature_sid: 12_345,
      goods_nomenclature_item_id: "0101210000",
      producline_suffix: "80",
      goods_nomenclature_type: "commodity",
      content: "Live horses are covered by chapter notes for chapter 1.",
      metadata: {
        "source_node_keys" => ["chapter_note:01:fragment:1"],
        "range_node_keys" => ["chapter:01"],
      },
      context_hash: "abc123",
      needs_review: true,
      manually_edited: false,
      stale: false,
      approved: false,
      expired: false,
      generated_at: "2025-06-15T10:00:00Z",
      created_at: "2025-06-15T10:00:00Z",
      updated_at: "#{Time.zone.today.iso8601}T10:00:00Z",
    }
  end

  describe "#to_param" do
    it "returns goods_nomenclature_sid as string" do
      expect(compressed_note.to_param).to eq("12345")
    end

    it "falls back to goods_nomenclature_id" do
      record = described_class.new(goods_nomenclature_id: "99999")

      expect(record.to_param).to eq("99999")
    end
  end

  describe "#source_node_keys" do
    it "returns source evidence node keys from metadata" do
      expect(compressed_note.source_node_keys).to eq(["chapter_note:01:fragment:1"])
    end

    it "returns an empty array when metadata is missing" do
      compressed_note.metadata = nil

      expect(compressed_note.source_node_keys).to eq([])
    end
  end

  describe "#range_node_keys" do
    it "returns referenced range node keys from metadata" do
      expect(compressed_note.range_node_keys).to eq(["chapter:01"])
    end
  end

  describe "#as_listing_json" do
    # rubocop:disable RSpec/ExampleLength
    it "uses content as the listing description and exposes lifecycle tags" do
      record = described_class.new(attributes.merge(lifecycle_tag_attributes))

      expect(record.as_listing_json).to include(
        lifecycle_tag_attributes.merge(
          content: "Live horses are covered by chapter notes for chapter 1.",
          score: nil,
        ),
      )
    end
    # rubocop:enable RSpec/ExampleLength
  end

  describe "record date formatting" do
    it "formats created_at" do
      expect(compressed_note.formatted_created_at).to eq("15 June 2025")
    end
  end

  describe ".find" do
    before do
      stub_api_request("/goods_nomenclatures/0101210000/tariff_knowledge_compressed_note")
        .with(query: hash_including("filter" => { "oid" => "789" }))
        .and_return(
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: {
            data: {
              type: "tariff_knowledge_compressed_note",
              id: "12345",
              attributes: attributes.merge(content: "Historical compressed note"),
            },
            meta: {
              version: {
                current: false,
                oid: 789,
                previous_oid: 788,
                has_previous_version: true,
                latest_event: "update",
              },
            },
          }.to_json,
        )
    end

    it "uses the path id and extracts version metadata through API entity", :aggregate_failures do
      record = described_class.find("0101210000", oid: "789")

      expect(record.goods_nomenclature_id).to eq("0101210000")
      expect(record.content).to eq("Historical compressed note")
      expect(record.version_oid).to eq(789)
      expect(record.current?).to be(false)
    end
  end

  def lifecycle_tag_attributes
    { needs_review: true, manually_edited: true, stale: true, approved: true, expired: true }
  end
end
