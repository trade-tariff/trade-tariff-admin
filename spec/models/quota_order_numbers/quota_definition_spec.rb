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
        formatted_measurement_unit: 'Kilogram (kg)',
        initial_volume: '18181000.0',
        quota_type: 'First Come First Served',
        critical_state: 'N',
        critical_threshold: '90',
      },
    )
  end

  describe '#quota_order_number' do
    context 'when there is an quota order number' do
      subject(:quota_definition) { build(:quota_definition, :with_quota_order_number) }

      it { expect(quota_definition.quota_order_number).to be_present }
      it { expect(quota_definition.quota_order_number).to be_instance_of QuotaOrderNumbers::QuotaOrderNumber }
    end

    context 'when there is not quota order number' do
      subject(:quota_definition) { build(:quota_definition, :without_quota_order_number) }

      it { expect(quota_definition.quota_order_number).to be_nil }
    end
  end

  describe '#quota_balance_events' do
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

      describe '#critical_thresholds' do
        it { expect(quota_definition.critical_thresholds).to eq([1_818_100.0]) }
      end

      describe '#initial_volumes' do
        it { expect(quota_definition.initial_volumes).to eq(['18181000.0']) }
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

      describe '#critical_thresholds' do
        it { expect(quota_definition.critical_thresholds).to eq([]) }
      end

      describe '#initial_volumes' do
        it { expect(quota_definition.initial_volumes).to eq([]) }
      end
    end
  end

  describe '#quota_order_number_origins' do
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

  describe '#quota_unsuspension_events' do
    context 'when there are quota unsuspension events' do
      subject(:quota_definition) { build(:quota_definition, :with_quota_unsuspension_events) }

      it { expect(quota_definition.quota_unsuspension_events.count).to eq(1) }

      it { expect(quota_definition.quota_unsuspension_events.first).to be_instance_of QuotaOrderNumbers::QuotaUnsuspensionEvent }
    end

    context 'when there are no quota unsuspension events' do
      subject(:quota_definition) { build(:quota_definition, :without_quota_unsuspension_events) }

      it { expect(quota_definition.quota_unsuspension_events).to eq([]) }
    end
  end

  describe '#quota_exhaustion_events' do
    context 'when there are quota exhaustion events' do
      subject(:quota_definition) { build(:quota_definition, :with_quota_exhaustion_events) }

      it { expect(quota_definition.quota_exhaustion_events.count).to eq(1) }

      it { expect(quota_definition.quota_exhaustion_events.first).to be_instance_of QuotaOrderNumbers::QuotaExhaustionEvent }
    end

    context 'when there are no quota exhaustion events' do
      subject(:quota_definition) { build(:quota_definition, :without_quota_exhaustion_events) }

      it { expect(quota_definition.quota_exhaustion_events).to eq([]) }
    end
  end

  describe '#quota_reopening_events' do
    context 'when there are quota reopening events' do
      subject(:quota_definition) { build(:quota_definition, :with_quota_reopening_events) }

      it { expect(quota_definition.quota_reopening_events.count).to eq(1) }

      it { expect(quota_definition.quota_reopening_events.first).to be_instance_of QuotaOrderNumbers::QuotaReopeningEvent }
    end

    context 'when there are no quota reopening events' do
      subject(:quota_definition) { build(:quota_definition, :without_quota_reopening_events) }

      it { expect(quota_definition.quota_reopening_events).to eq([]) }
    end
  end

  describe '#quota_unblocking_events' do
    context 'when there are quota unblocking events' do
      subject(:quota_definition) { build(:quota_definition, :with_quota_unblocking_events) }

      it { expect(quota_definition.quota_unblocking_events.count).to eq(1) }

      it { expect(quota_definition.quota_unblocking_events.first).to be_instance_of QuotaOrderNumbers::QuotaUnblockingEvent }
    end

    context 'when there are no quota unblocking events' do
      subject(:quota_definition) { build(:quota_definition, :without_quota_unblocking_events) }

      it { expect(quota_definition.quota_unblocking_events).to eq([]) }
    end
  end

  describe '#quota_critical_events' do
    context 'when there are quota critical events' do
      subject(:quota_definition) { build(:quota_definition, :with_quota_critical_events) }

      it { expect(quota_definition.quota_critical_events.count).to eq(1) }

      it { expect(quota_definition.quota_critical_events.first).to be_instance_of QuotaOrderNumbers::QuotaCriticalEvent }
    end

    context 'when there are no quota unblocking events' do
      subject(:quota_definition) { build(:quota_definition, :without_quota_critical_events) }

      it { expect(quota_definition.quota_critical_events).to eq([]) }
    end
  end

  describe '#quota_additional_events' do
    context 'when there are quota additional events' do
      subject(:quota_definition) do
        build(:quota_definition, :with_quota_critical_events,
              :with_quota_unsuspension_events,
              :with_quota_exhaustion_events,
              :with_quota_reopening_events,
              :with_quota_unblocking_events)
      end

      it { expect(quota_definition.additional_events.count).to eq(5) }
    end

    context 'when there are no quota additional events' do
      subject(:quota_definition) do
        build(:quota_definition, :without_quota_critical_events,
              :without_quota_unsuspension_events,
              :without_quota_exhaustion_events,
              :without_quota_reopening_events,
              :without_quota_unblocking_events)
      end

      it { expect(quota_definition.additional_events).to eq([]) }
    end
  end

  describe '#formatted_initial_volume' do
    subject(:formatted_initial_volume) { build(:quota_definition).formatted_initial_volume }

    it { is_expected.to eq('18,181,000.000 Kilogram (kg)') }
  end

  describe '#last_balance_row_heading' do
    subject(:last_balance_row_heading) { build(:quota_definition).last_balance_row_heading }

    it { is_expected.to eq('Last balance (kg)') }
  end

  describe '#imported_amount_row_heading' do
    subject(:imported_amount_row_heading) { build(:quota_definition).imported_amount_row_heading }

    it { is_expected.to eq('Imported amount (kg)') }
  end

  describe '#new_balance_row_heading' do
    subject(:new_balance_row_heading) { build(:quota_definition).new_balance_row_heading }

    it { is_expected.to eq('New balance (kg)') }
  end
end
