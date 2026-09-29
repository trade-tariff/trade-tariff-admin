# rubocop:disable RSpec/MultipleExpectations
RSpec.describe TariffKnowledgeSyntheticAtar do
  subject(:synthetic_atar) { described_class.new(attributes) }

  let(:attributes) do
    {
      resource_id: 12,
      real_user_search: "plastic box",
      chapter: "39",
      times_searched: 25,
      goods_nomenclature_item_id: "3924100000",
      description: "Reusable plastic food storage box with a clip-on lid, made of polypropylene, for household use.",
      completed_by: "AB",
    }
  end

  it "talks to the flat prefixed backend endpoint" do
    expect(described_class.collection_path).to eq("admin/tariff_knowledge_synthetic_atars")
    expect(synthetic_atar.singular_path).to eq("admin/tariff_knowledge_synthetic_atars/12")
  end

  it "is only available on the UK service" do
    expect(described_class).to be_uk_only
  end

  describe "#description_summary" do
    it "truncates a long description" do
      expect(synthetic_atar.description_summary.length).to be <= 90
      expect(synthetic_atar.description_summary).to end_with("...")
    end

    it "returns a short description as it is" do
      expect(described_class.new(description: "A box").description_summary).to eq("A box")
    end
  end

  describe "#times_searched_label" do
    it "returns the number" do
      expect(synthetic_atar.times_searched_label).to eq(25)
    end

    it "returns a dash when it is not set" do
      expect(described_class.new(times_searched: nil).times_searched_label).to eq("-")
    end
  end

  describe TariffKnowledgeSyntheticAtar::BulkImportResult do
    it "summarises the counts" do
      result = described_class.new(created: 2, updated: 1, unchanged: 3, skipped: 470)

      expect(result).to be_success
      expect(result.total).to eq(6)
      expect(result.message).to eq("Imported 6 synthetic ATaRs: 2 created, 1 updated, 3 unchanged. 470 rows skipped because they are not finished.")
    end

    it "uses the singular for one" do
      result = described_class.new(created: 1, skipped: 1)

      expect(result.message).to eq("Imported 1 synthetic ATaR: 1 created, 0 updated, 0 unchanged. 1 row skipped because they are not finished.")
    end

    it "is not a success when there are errors" do
      expect(described_class.new(errors: [{ "detail" => "Line 2: something is wrong" }])).not_to be_success
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
