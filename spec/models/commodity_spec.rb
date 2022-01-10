require 'rails_helper'

RSpec.describe Commodity do
  describe '#export_filename' do
    subject(:result) { build(:commodity, id: '0201000023-10').export_filename }

    it { is_expected.to match(/^commodities-0201000023-10-synonyms-\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\.csv/) }
  end
end
