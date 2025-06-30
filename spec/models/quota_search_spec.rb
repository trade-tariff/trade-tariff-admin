RSpec.describe QuotaSearch do
  subject(:quota_search) { described_class.new(attributes) }

  describe 'validations' do
    let(:today) { Time.zone.today }

    let(:base_attributes) do
      {
        order_number: '123456',
        'import_date(3i)': today.day.to_s,
        'import_date(2i)': today.month.to_s,
        'import_date(1i)': today.year.to_s,
      }
    end

    context 'when the order number is 6 numerical chars' do
      let(:attributes) { base_attributes.merge(order_number: '123456') }

      it { is_expected.to be_valid }
    end

    context 'when the order number is not 6 numerical chars' do
      let(:attributes) { base_attributes.merge(order_number: '1456') }

      it { is_expected.not_to be_valid }
    end

    context 'when the order number is not numerical chars' do
      let(:attributes) { base_attributes.merge(order_number: 'abcdef') }

      it { is_expected.not_to be_valid }
    end
  end
end
