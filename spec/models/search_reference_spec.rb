RSpec.describe SearchReference do
  describe ".collection_options" do
    let(:parent) { build(:commodity) }

    it "adds a filter for a known usage" do
      expect(described_class.collection_options(casted_by: parent, usage: "fpo"))
        .to eq(casted_by: parent, filter: { usage: "fpo" })
    end

    it "adds a filter for all usages" do
      expect(described_class.collection_options(casted_by: parent, usage: "all"))
        .to eq(casted_by: parent, filter: { usage: "all" })
    end

    it "does not add a filter when usage is blank" do
      expect(described_class.collection_options(casted_by: parent)).to eq(casted_by: parent)
    end

    it "does not add a filter for an unknown usage" do
      expect(described_class.collection_options(casted_by: parent, usage: "other")).to eq(casted_by: parent)
    end
  end

  describe "#fpo?" do
    it { expect(described_class.new(usage: "fpo")).to be_fpo }
    it { expect(described_class.new(usage: "search")).not_to be_fpo }
  end

  describe "#usage_name" do
    it { expect(described_class.new(usage: "fpo").usage_name).to eq("FPO only") }
    it { expect(described_class.new(usage: "search").usage_name).to eq("Search") }
    it { expect(described_class.new.usage_name).to eq("Search") }
  end

  describe "#serializable_hash" do
    it "includes usage" do
      reference = described_class.new(title: "foo", usage: "fpo", release_to_uk: 1)

      expect(reference.serializable_hash.dig(:data, :attributes)).to include(usage: "fpo")
    end
  end
end
