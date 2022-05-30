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
    context 'when the filename contains an gzip suffix' do
      subject(:id) { build(:tariff_update, filename: 'foo.gzip').id }

      it { is_expected.to eq('foo') }
    end

    context 'when the filename contains an xml suffix' do
      subject(:id) { build(:tariff_update, filename: 'foo.xml').id }

      it { is_expected.to eq('foo') }
    end
  end

  describe '#parsed_inserts' do
    subject(:parsed_inserts) { build(:tariff_update, inserts:).parsed_inserts }

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
