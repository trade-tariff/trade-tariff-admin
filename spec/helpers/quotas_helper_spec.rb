require 'rails_helper'

RSpec.describe QuotasHelper do
  describe '#formatted_initial_volume' do
    subject(:formatted_initial_volume) { helper.formatted_initial_volume(quota_definition) }

    let(:quota_definition) { build(:quota_definition) }

    it { is_expected.to eq('18,181,000.000 Kilogram (kg)') }
  end

  describe '#format_quota_dates' do
    subject { format_quota_dates quota_order_number_origin }

    context 'with both validity start and validity end dates present' do
      let(:quota_order_number_origin) { build :quota_order_number_origin }

      it { is_expected.to eql 'from 1 July 2021 to 1 July 2029' }
    end

    context 'with validity start date only' do
      let(:quota_order_number_origin) { build :quota_order_number_origin, validity_end_date: nil }

      it { is_expected.to eql 'from 1 July 2021' }
    end
  end
end
