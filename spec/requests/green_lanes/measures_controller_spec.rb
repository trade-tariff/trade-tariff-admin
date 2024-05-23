RSpec.describe GreenLanes::ExemptionsController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:create_user) { create :user, permissions: ['signin', 'HMRC Editor'] }

  before do
    allow(TradeTariffAdmin::ServiceChooser).to receive(:service_choice).and_return 'xi'
  end

  describe 'GET #index' do
    before do
      stub_api_request('/admin/green_lanes/measures?page=1', backend: 'xi').and_return \
        jsonapi_response :measures, build_list(:green_lanes_measure, 3, :with_category_assessment, :with_goods_nomenclature)
    end

    let(:make_request) { get green_lanes_measures_path }

    it { is_expected.to have_http_status :success }
    it { is_expected.not_to include 'div.current-service' }
  end
end
