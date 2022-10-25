require 'rails_helper'

RSpec.describe QuotaSearch do
  subject(:quota_search) { described_class.new(attributes) }

  describe 'validations' do
    context 'when the order number is 6 numerical chars' do
      let(:attributes) { { order_number: '123456' } }

      it { is_expected.to be_valid }
    end

    context 'when the order number is not 6 numerical chars' do
      let(:attributes) { { order_number: '1456' } }

      it { is_expected.not_to be_valid }
    end

    context 'when the order number is not numerical chars' do
      let(:attributes) { { order_number: 'abcdef' } }

      it { is_expected.not_to be_valid }
    end
  end
end
