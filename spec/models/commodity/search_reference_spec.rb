require 'rails_helper'

RSpec.describe Commodity::SearchReference do
  describe '#referenced_id=' do
    subject(:search_reference) { build(:commodity_search_reference, productline_suffix: '80') }

    before do
      search_reference.referenced_id = referenced_id
    end

    context 'when the referenced id is a composite goods_nomenclature_item_id and productline_suffix' do
      let(:referenced_id) { '0201000023-10' }

      it { is_expected.to have_attributes(referenced_id: '0201000023', productline_suffix: '10') }
    end

    context 'when the referenced id is a goods_nomenclature_item_id' do
      let(:referenced_id) { '0201000023' }

      it { is_expected.to have_attributes(referenced_id: '0201000023', productline_suffix: '80') }
    end
  end
end
