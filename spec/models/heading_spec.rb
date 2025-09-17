RSpec.describe Heading do
  describe "#reference_title" do
    subject(:result) { heading.reference_title }

    let(:heading) do
      build(
        :heading,
        goods_nomenclature_item_id: "0101000000",
        description: "Live Horses",
      )
    end

    it { is_expected.to eq("heading 0101: Live Horses") }
  end
end
