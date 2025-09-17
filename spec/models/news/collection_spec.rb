require "rails_helper"

RSpec.describe News::Collection do
  subject(:news_collection) { build :news_collection }

  it { expect(described_class).to be_uk_only }

  it { is_expected.to respond_to :id }
  it { is_expected.to respond_to :name }
  it { is_expected.to respond_to :description }
  it { is_expected.to respond_to :priority }
  it { is_expected.to respond_to :published }
  it { is_expected.to respond_to :subscribable }

  describe "#generate_or_normalise_slug!" do
    subject { news_collection.generate_or_normalise_slug! }

    context "when a slug is already present" do
      let(:news_collection) { build :news_collection, slug: "foo-bar" }

      it { is_expected.to be_nil }
    end

    context "when a name is present" do
      let(:news_collection) { build :news_collection, name: "Foo Bar", slug: nil }

      it { is_expected.to eq "foo-bar" }
    end
  end
end
