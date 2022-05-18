RSpec.describe ReportsController do
  subject(:do_response) { make_request && response }

  before do
    create :user, permissions: %w[signin]
  end

  describe 'GET #index' do
    let(:make_request) { get reports_path }

    it { is_expected.to have_http_status :success }

    it 'contain the report' do
      make_request

      expect(do_response.body).to include('Commodities extract')
    end
  end

  describe 'GET #show' do
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

    let(:make_request) { get report_path('commodities', format: :csv) }

    it { is_expected.to have_http_status :success }

    it 'returns the report csv' do
      make_request

      expect(do_response.body).to include("foo,bar\nbaz,qux\n")
    end

    it 'returns the report filename' do
      make_request

      expect(do_response['content-disposition']).to include('filename=uk-commodities-2022-05-18.csv')
    end
  end
end
