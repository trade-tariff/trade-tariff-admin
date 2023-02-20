require 'rails_helper'

RSpec.describe Heading do
  describe '#export_filename' do
    subject(:result) { build(:heading, goods_nomenclature_item_id: '0201000000').export_filename }

    it { is_expected.to match(/^headings-0201-references-\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\.csv/) }
  end

  describe '#reference_title' do
    subject(:result) do
      build(
        :heading,
        goods_nomenclature_item_id: '0101000000',
        description: 'Live Horses',
      ).reference_title
    end

    it { is_expected.to eq('heading 0101: Live Horses') }
  end
end
