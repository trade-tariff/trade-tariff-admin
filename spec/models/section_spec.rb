require 'rails_helper'

RSpec.describe Section do
  describe '#export_filename' do
    subject(:result) { build(:section, position: 'XI').export_filename }

    it { is_expected.to match(/^sections-XI-references-\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\.csv/) }
  end
end
