RSpec.describe Update::Inserts do
  describe '#total_duration_in_seconds' do
    subject(:total_duration_in_seconds) { build(:update, :with_inserts).inserts.total_duration_in_seconds }

    it { is_expected.to eq(5.197715087890625) }
  end

  describe '#total_records_affected' do
    subject(:total_records_affected) { build(:update, :with_inserts).inserts.total_records_affected }

    it { is_expected.to eq(3002) }
  end

  describe '#total_records_created' do
    subject(:total_records_created) { build(:update, :with_inserts).inserts.total_records_created }

    it { is_expected.to eq(2909) }
  end

  describe '#total_records_updated' do
    subject(:total_records_updated) { build(:update, :with_inserts).inserts.total_records_updated }

    it { is_expected.to eq(93) }
  end

  describe '#total_records_destroyed' do
    subject(:total_records_destroyed) { build(:update, :with_inserts).inserts.total_records_destroyed }

    it { is_expected.to eq(4) }
  end

  describe '#updated_entities' do
    subject(:updated_entities) { build(:update, :with_inserts).inserts.updated_entities }

    let(:expected_updated_entities) do
      [
        { entity: 'QuotaBalanceEvent', creates: 2869, updates: 0, destroys: 0 },
        { entity: 'QuotaAssociation', creates: 12, updates: 0, destroys: 0 },
        { entity: 'QuotaCriticalEvent', creates: 12, updates: 0, destroys: 0 },
        { entity: 'QuotaReopeningEvent', creates: 5, updates: 0, destroys: 0 },
        { entity: 'QuotaExhaustionEvent', creates: 10, updates: 0, destroys: 0 },
        { entity: 'MeasureExcludedGeographicalArea', creates: 1, updates: 0, destroys: 0 },
        { entity: 'QuotaDefinition', creates: 0, updates: 57, destroys: 0 },
        { entity: 'Measure', creates: 0, updates: 18, destroys: 0 },
        { entity: 'MeasureComponent', creates: 0, updates: 18, destroys: 0 },
      ]
    end

    it { is_expected.to eq(expected_updated_entities) }
  end

  describe '#any_updates?' do
    context 'when there are inserts' do
      subject(:inserts) { build(:update, :with_inserts).inserts }

      it { is_expected.to be_any_updates }
    end

    context 'when there are no inserts' do
      subject(:inserts) { build(:update, :with_empty_inserts).inserts }

      it { is_expected.not_to be_any_updates }
    end
  end

  describe '#updated_inserts?' do
    context 'when the new format of inserts are present' do
      subject(:inserts) { build(:update, :with_inserts).inserts }

      it { is_expected.to be_updated_inserts }
    end

    context 'when the old format of inserts are present' do
      subject(:inserts) { build(:update, :with_old_inserts).inserts }

      it { is_expected.not_to be_updated_inserts }
    end
  end

  describe '#parsed_inserts' do
    subject(:parsed_inserts) { build(:update, inserts:).inserts.parsed_inserts }

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
