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
end
# rubocop:enable RSpec/MultipleExpectations
