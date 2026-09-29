RSpec.describe Version do
  subject(:version) { described_class.new(object: object) }

  describe "#item_description" do
    context "when the object is not a hash" do
      let(:object) { nil }

      it "returns nil" do
        expect(version.item_description).to be_nil
      end
    end

    context "when the object has a real user search and a commodity code" do
      # A synthetic ATaR always has both. The search is what identifies the
      # record to a person browsing the history list — every row has a code,
      # so the code alone can't tell two rows apart.
      let(:object) { { "real_user_search" => "lunch box", "goods_nomenclature_item_id" => "3924100000" } }

      it "prefers the real user search" do
        expect(version.item_description).to eq("lunch box")
      end
    end

    context "when the object has a commodity code but no real user search" do
      let(:object) { { "goods_nomenclature_item_id" => "3924100000" } }

      it "falls back to the commodity code" do
        expect(version.item_description).to eq("3924100000")
      end
    end

    context "when the object has a term" do
      let(:object) { { "term" => "animal feed" } }

      it "falls back to the term" do
        expect(version.item_description).to eq("animal feed")
      end
    end

    context "when the object has none of the known fields" do
      subject(:version) { described_class.new(object: object, item_id: "42") }

      let(:object) { { "something_else" => "value" } }

      it "falls back to the item id" do
        expect(version.item_description).to eq("42")
      end
    end
  end
end
