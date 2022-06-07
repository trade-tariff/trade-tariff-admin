require 'rails_helper'

RSpec.describe Chapter do
  describe '#export_filename' do
    subject(:result) { build(:chapter, goods_nomenclature_item_id: '0200000000').export_filename }

    it { is_expected.to match(/^chapters-02-references-\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\.csv/) }
  end
end
