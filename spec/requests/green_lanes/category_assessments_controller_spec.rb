RSpec.describe GreenLanes::CategoryAssessmentsController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:category_assessment) { build :category_assessment }
  let(:create_user) { create :user, permissions: ['signin', 'HMRC Editor'] }

  before do
    allow(TradeTariffAdmin::ServiceChooser).to receive(:service_choice).and_return 'xi'
  end

  describe 'GET #index' do
    before do
      stub_api_request('/admin/green_lanes/category_assessments?page=1', backend: 'xi').and_return \
        jsonapi_response :category_assessments, attributes_for_list(:category_assessment, 3)
    end

    let(:make_request) { get green_lanes_category_assessments_path }

    it { is_expected.to have_http_status :success }
    it { is_expected.not_to include 'div.current-service' }
  end

  describe 'GET #new' do
    before do
      stub_api_request('/admin/green_lanes/themes', backend: 'xi').and_return \
        jsonapi_response :themes, attributes_for_list(:green_lanes_theme, 3)
    end

    let(:make_request) { get new_green_lanes_category_assessment_path }

    it { is_expected.to have_http_status :ok }
    it { is_expected.not_to include 'div.current-service' }
  end

  describe 'POST #create' do
    before do
      stub_api_request('/admin/green_lanes/category_assessments', :post).to_return create_response
      stub_api_request('/admin/green_lanes/themes', backend: 'xi').and_return \
        jsonapi_response :themes, attributes_for_list(:green_lanes_theme, 3)
    end

    let :make_request do
      post green_lanes_category_assessments_path,
           params: { category_assessment: ca_params }
    end

    context 'with valid item' do
      let(:ca_params) { category_assessment.attributes.without(:id) }
      let(:create_response) { webmock_response(:created, category_assessment.attributes) }

      it { is_expected.to redirect_to green_lanes_category_assessments_path }
    end

    context 'with invalid item' do
      let(:ca_params) { category_assessment.attributes.without(:id, :measure_type_id) }
      let(:create_response) { webmock_response(:error, measure_type_id: "can't be blank'") }

      it { is_expected.to have_http_status :ok }
      it { is_expected.to have_attributes body: /can.+t be blank/ }
      it { is_expected.not_to include 'div.current-service' }
    end
  end
end
