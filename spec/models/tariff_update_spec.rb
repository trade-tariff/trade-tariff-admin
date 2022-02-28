RSpec.describe TariffUpdate do
  describe '#state' do
    shared_examples_for 'a tariff update state' do |actual_state, expected_state|
      subject(:state) { build(:tariff_update, state: actual_state).state }

      it { is_expected.to eq(expected_state) }
    end

    it_behaves_like 'a tariff update state', 'A', 'Applied'
    it_behaves_like 'a tariff update state', 'P', 'Pending'
    it_behaves_like 'a tariff update state', 'F', 'Failed'
    it_behaves_like 'a tariff update state', 'X', nil
  end

  describe '#inserts' do
    context 'when the inserts are supplied' do
      subject(:inserts) { build(:tariff_update, :with_inserts).inserts }

      it { is_expected.to eq('something' => 'parseable') }
    end

    context 'when the inserts are not supplied' do
      subject(:inserts) { build(:tariff_update).inserts }

      it { is_expected.to eq({}) }
    end
  end

  describe '#rollback?' do
    shared_examples_for 'a tariff update that rolls back' do |state, _will_rollback|
      subject(:tariff_update) { build(:tariff_update, state:) }

      it { is_expected.to be_rollback }
    end

    shared_examples_for 'a tariff update that does not rollback' do |state, _will_rollback|
      subject(:tariff_update) { build(:tariff_update, state:) }

      it { is_expected.not_to be_rollback }
    end

    it_behaves_like 'a tariff update that rolls back', 'A'

    it_behaves_like 'a tariff update that does not rollback', 'F'
    it_behaves_like 'a tariff update that does not rollback', 'P'
    it_behaves_like 'a tariff update that does not rollback', 'X'
  end

  describe '#issue_date' do
    subject(:issue_date) { build(:tariff_update, issue_date: Time.zone.today.iso8601).issue_date }

    it { is_expected.to eq(Time.zone.today) }
  end

  describe '#applied_at' do
    subject(:issue_date) { build(:tariff_update, applied_at: now.iso8601).applied_at }

    let(:now) { Time.zone.now }

    it { is_expected.to eq(Time.zone.parse(now.iso8601)) }
  end

  describe '#id' do
    subject(:id) { build(:tariff_update, created_at: '2022-01-01T12:13Z').id }

    it { is_expected.to eq('2022-01-01t12-13z') }
  end
end
