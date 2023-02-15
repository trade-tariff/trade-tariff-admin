require 'rails_helper'

RSpec.describe NewsCollectionsHelper do
  describe '#news_collection_bool' do
    subject { news_collection_bool value }

    context 'with a truthy value' do
      let(:value) { true }

      it { is_expected.to eql 'Yes' }
    end

    context 'with a falsy value' do
      let(:value) { nil }

      it { is_expected.to eql 'No' }
    end
  end
end
