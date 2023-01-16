require 'rails_helper'

RSpec.describe QuotaOrderNumbers::QuotaDefinition do
  subject(:quota_definition) { build(:quota_definition) }

  it 'implements the correct attributes' do
    expect(quota_definition).to have_attributes(
      {
        id: '22619',
        quota_order_number_id: '051822',
        validity_start_date: '2022-01-01T00:00:00.000Z',
        validity_end_date: '2022-12-31T23:59:59.000Z',
        measurement_unit: 'Kilogram (kg)',
        initial_volume: '18181000.0',
        quota_type: 'First Come First Served',
      },
    )
  end

  context 'when there are quota balance events' do
    subject(:quota_definition) { build(:quota_definition, :with_quota_balance_events) }

    describe '#occurrence_timestamps' do
      it { expect(quota_definition.occurrence_timestamps).to eq(['12 Jan 2022']) }
    end

    describe '#imported_amounts' do
      it { expect(quota_definition.imported_amounts).to eq(['35040.0']) }
    end

    describe '#new_balances' do
      it { expect(quota_definition.new_balances).to eq(['18145960.0']) }
    end
  end

  context 'when there are no quota balance events' do
    subject(:quota_definition) { build(:quota_definition, :without_quota_balance_events) }

    describe '#occurrence_timestamps' do
      it { expect(quota_definition.occurrence_timestamps).to eq([]) }
    end

    describe '#imported_amounts' do
      it { expect(quota_definition.imported_amounts).to eq([]) }
    end

    describe '#new_balances' do
      it { expect(quota_definition.new_balances).to eq([]) }
    end
  end

  context 'quota order number origins' do
    context 'when there are quota order number origins' do
      subject(:quota_definition) { build(:quota_definition, :with_quota_order_number_origins) }
  
      it { expect(quota_definition.quota_order_number_origins.count).to eq(1) }
      
      it { expect(quota_definition.quota_order_number_origins.first).to be_instance_of QuotaOrderNumbers::QuotaOrderNumberOrigin }
    end

    context 'when there are no quota order number origins' do
      subject(:quota_definition) { build(:quota_definition, :without_quota_order_number_origins) }
  
      it { expect(quota_definition.quota_order_number_origins).to eq([]) }
    end
  end
end
