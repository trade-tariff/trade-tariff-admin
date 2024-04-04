RSpec.describe GreenLanes::CategoryAssessmentsController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:category_assessment) { build :category_assessment }
  let(:create_user) { create :user, permissions: ['signin', 'HMRC Editor'] }

  before do
    allow(TradeTariffAdmin::ServiceChooser).to receive(:service_choice).and_return 'xi'
  end

  describe 'GET #index' do
    before do
      stub_api_request('/admin/category_assessments?page=1', backend: 'xi').and_return \
        jsonapi_response :category_assessments, attributes_for_list(:category_assessment, 3)
    end

    let(:make_request) { get green_lanes_category_assessments_path }

    it { is_expected.to have_http_status :success }
  end
end
