RSpec.describe GreenLanes::ExemptionsController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:exemption) { build :exemption }
  let(:create_user) { create :user, permissions: ['signin', 'HMRC Editor'] }

  before do
    allow(TradeTariffAdmin::ServiceChooser).to receive(:service_choice).and_return 'xi'
  end

  describe 'GET #index' do
    before do
      stub_api_request('/admin/green_lanes/exemptions', backend: 'xi').and_return \
        jsonapi_response :exemptions, attributes_for_list(:exemption, 3)
    end

    let(:make_request) { get green_lanes_exemptions_path }

    it { is_expected.to have_http_status :success }
    it { is_expected.not_to include 'div.current-service' }
  end
end
