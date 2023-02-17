require 'rails_helper'

RSpec.describe News::Collection do
  subject(:news_collection) { build :news_collection }

  it { is_expected.to respond_to :id }
  it { is_expected.to respond_to :name }
  it { is_expected.to respond_to :description }
  it { is_expected.to respond_to :priority }
  it { is_expected.to respond_to :published }

  describe 'slug generation' do
    subject { news_collection.slug }

    let(:news_collection) { build :news_collection, slug: nil }

    it { is_expected.to be_blank }

    context 'when after validation called' do
      before { news_collection.valid? }

      it { is_expected.to be_present }

      context 'with manually assigned slug' do
        let(:news_collection) { build :news_collection, slug: 'some-test-slug' }

        it { is_expected.to eql 'some-test-slug' }
      end
    end
  end
end
