require 'rails_helper'

RSpec.describe QuotasHelper do
  describe '#format_quota_dates' do
    subject { format_quota_dates quota_order_number_origin }

    let(:quota_order_number_origin) { build :quota_order_number_origin }

    context 'with both validity start and validity end dates present' do
      it { is_expected.to eql 'from 1 July 2021 to 1 July 2029' }
    end

    context 'with validity start date only' do
      before { quota_order_number_origin.validity_end_date = nil }
      
      it { is_expected.to eql 'from 1 July 2021' }
    end
  end
end
