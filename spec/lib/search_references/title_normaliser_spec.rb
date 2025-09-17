RSpec.describe SearchReferences::TitleNormaliser do
  describe "#normalise_title" do
    subject(:normalised_title) { described_class.normalise_title(title) }

    context "when the title is empty" do
      let(:title) { "" }

      it { is_expected.to eq("") }
    end

    context "when the title includes odd capitalisation" do
      let(:title) { "odd caPitalIsation" }

      it { is_expected.to eq("odd capitalisation") }
    end

    context "when the title includes nbsp" do
      let(:title) { "foo#{160.chr('UTF-8')}bar" }

      it { is_expected.to eq("foo bar") }
    end

    context "when the title includes commas" do
      let(:title) { "cows,    live" }

      it { is_expected.to eq("cows, live") }
    end
  end
end
