RSpec.describe GreenLanes::MeasuresController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:measure) { build :green_lanes_measure, :with_category_assessment }
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

  describe 'POST #create' do
    before do
      stub_api_request('/admin/green_lanes/measures', :post).to_return create_response
    end

    let :make_request do
      post green_lanes_measures_path(id: measure.category_assessment_id),
           params: { measure: measure_params }
    end

    context 'with valid item' do
      let(:measure_params) { measure.attributes.without(:id) }
      let(:create_response) { webmock_response(:created, measure.attributes) }

      it { is_expected.to redirect_to edit_green_lanes_category_assessment_path(id: measure.category_assessment_id) }
    end

    context 'with invalid item' do
      let(:measure_params) { measure.attributes.without(:id, :goods_nomenclature_item_id) }
      let(:create_response) { webmock_response(:error, measure: "can't be blank'") }

      it { is_expected.to have_http_status :redirect }

      it 'sets the session' do
        rendered_page

        expect(
          session['measures_errors'],
        ).to include("Goods nomenclature item can't be blank")
      end
    end
  end
end
