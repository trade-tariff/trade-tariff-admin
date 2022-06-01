RSpec.describe TariffUpdate::Inserts do
  describe '#total_duration_in_seconds' do
    subject(:total_duration_in_seconds) { build(:tariff_update, :with_inserts).inserts.total_duration_in_seconds }

    it { is_expected.to eq(5.197715087890625) }
  end

  describe '#total_records_affected' do
    subject(:total_records_affected) { build(:tariff_update, :with_inserts).inserts.total_records_affected }

    it { is_expected.to eq(3002) }
  end

  describe '#total_records_created' do
    subject(:total_records_created) { build(:tariff_update, :with_inserts).inserts.total_records_created }

    it { is_expected.to eq(2909) }
  end

  describe '#total_records_updated' do
    subject(:total_records_updated) { build(:tariff_update, :with_inserts).inserts.total_records_updated }

    it { is_expected.to eq(93) }
  end

  describe '#total_records_destroyed' do
    subject(:total_records_destroyed) { build(:tariff_update, :with_inserts).inserts.total_records_destroyed }

    it { is_expected.to eq(4) }
  end

  describe '#total_records_destroyed_missing' do
    subject(:total_records_destroyed_missing) { build(:tariff_update, :with_inserts).inserts.total_records_destroyed_missing }

    it { is_expected.to eq(7) }
  end

  describe '#total_records_destroyed_cascade' do
    subject(:total_records_destroyed_cascade) { build(:tariff_update, :with_inserts).inserts.total_records_destroyed_cascade }

    it { is_expected.to eq(5) }
  end

  describe '#updated_entities' do
    subject(:updated_entities) { build(:tariff_update, :with_inserts).inserts.updated_entities }

    let(:expected_updated_entities) do
      [
        { entity: 'QuotaBalanceEvent', creates: 2869, updates: 0, destroys: 0, missing: 0 },
        { entity: 'QuotaAssociation', creates: 12, updates: 0, destroys: 0, missing: 0 },
        { entity: 'QuotaCriticalEvent', creates: 12, updates: 0, destroys: 0, missing: 0 },
        { entity: 'QuotaReopeningEvent', creates: 5, updates: 0, destroys: 0, missing: 0 },
        { entity: 'QuotaExhaustionEvent', creates: 10, updates: 0, destroys: 0, missing: 0 },
        { entity: 'MeasureExcludedGeographicalArea', creates: 1, updates: 0, destroys: 0, missing: 1 },
        { entity: 'QuotaDefinition', creates: 0, updates: 57, destroys: 0, missing: 0 },
        { entity: 'Measure', creates: 0, updates: 18, destroys: 0, missing: 0 },
        { entity: 'MeasureComponent', creates: 0, updates: 18, destroys: 0, missing: 0 },
      ]
    end

    it { is_expected.to eq(expected_updated_entities) }
  end

  describe '#missing_entities' do
    subject(:missing_entities) { build(:tariff_update, :with_inserts).inserts.missing_entities }

    let(:expected_missing_entities) do
      [
        {
          entity: 'MeasureExcludedGeographicalArea',
          missing: 1,
          records: "---\n- oid: 1\n  measure_sid: 123\n  geographical_area_id: IT\n",
        },
      ]
    end

    it { is_expected.to eq(expected_missing_entities) }
  end

  describe '#any_updates?' do
    context 'when there are inserts' do
      subject(:inserts) { build(:tariff_update, :with_inserts).inserts }

      it { is_expected.to be_any_updates }
    end

    context 'when there are no inserts' do
      subject(:inserts) { build(:tariff_update, :with_empty_inserts).inserts }

      it { is_expected.not_to be_any_updates }
    end
  end

  describe '#any_missing?' do
    context 'when there are missing inserts' do
      subject(:inserts) { build(:tariff_update, :with_inserts).inserts }

      it { is_expected.to be_any_missing }
    end

    context 'when there are no inserts' do
      subject(:inserts) { build(:tariff_update, :with_empty_inserts).inserts }

      it { is_expected.not_to be_any_missing }
    end
  end

  describe '#updated_inserts?' do
    context 'when the new format of inserts are present' do
      subject(:inserts) { build(:tariff_update, :with_inserts).inserts }

      it { is_expected.to be_updated_inserts }
    end

    context 'when the old format of inserts are present' do
      subject(:inserts) { build(:tariff_update, :with_old_inserts).inserts }

      it { is_expected.not_to be_updated_inserts }
    end
  end

  describe '#parsed_inserts' do
    subject(:parsed_inserts) { build(:tariff_update, inserts:).inserts.parsed_inserts }

    context 'when there are inserts' do
      let(:inserts) { '{"foo":"bar"}' }

      it { is_expected.to eq('foo' => 'bar') }
    end

    context 'when there are no inserts' do
      let(:inserts) { '{}' }

      it { is_expected.to eq({}) }
    end
  end
end
