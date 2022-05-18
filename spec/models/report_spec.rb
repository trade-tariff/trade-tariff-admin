require 'rails_helper'

RSpec.describe Report do
  subject(:report) { described_class.build('commodities') }

  before do
    stub_request(:get, "#{TradeTariffAdmin::ServiceChooser.api_host}/admin/commodities.csv").and_return(
      status: 200,
      headers: {
        'content-disposition' => 'attachment; filename=uk-commodities-2022-05-18.csv',
        'content-type' => 'text/csv; charset=utf-8',
        'content-transfer-encoding' => 'binary',
      },
      body: "foo,bar\nbaz,qux\n",
    )
  end

  describe '.build' do
    it { is_expected.to be_a(described_class) }
  end

  describe '#csv_data' do
    it { expect(report.csv_data).to eq("foo,bar\nbaz,qux\n") }
  end

  describe '#filename' do
    it { expect(report.filename).to eq('uk-commodities-2022-05-18.csv') }
  end
end
