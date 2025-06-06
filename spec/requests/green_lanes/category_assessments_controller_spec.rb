RSpec.describe GreenLanes::CategoryAssessmentsController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:category_assessment) { build :category_assessment, :with_theme, :with_measure_pagination }
  let(:create_user) { create :user, permissions: ['signin', 'HMRC Editor'] }

  before do
    allow(TradeTariffAdmin::ServiceChooser).to receive(:service_choice).and_return 'xi'

    stub_api_request('/admin/green_lanes/themes', backend: 'xi').and_return \
      jsonapi_response :themes, attributes_for_list(:green_lanes_theme, 3)

    stub_api_request('/admin/green_lanes/exemptions', backend: 'xi').and_return \
      jsonapi_response :exemptions, attributes_for_list(:exemption, 3)
  end

  describe 'GET #index' do
    before do
      stub_api_request('/admin/green_lanes/category_assessments?query[page]=1&query[sort]&query[direction]', backend: 'xi').and_return \
        jsonapi_response :category_assessments, attributes_for_list(:category_assessment, 3, :with_theme)
    end

    let(:make_request) { get green_lanes_category_assessments_path, params: { filters: {} } }

    it { is_expected.to have_http_status :success }
    it { is_expected.not_to include 'div.current-service' }
  end

  describe 'GET #new' do
    let(:make_request) { get new_green_lanes_category_assessment_path }

    it { is_expected.to have_http_status :ok }
    it { is_expected.not_to include 'div.current-service' }
  end

  describe 'POST #create' do
    before do
      stub_api_request('/admin/green_lanes/category_assessments', :post).to_return create_response
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

  describe 'GET #edit' do
    before do
      stub_api_request("/admin/green_lanes/category_assessments/#{category_assessment.id}?page=1")
        .and_return jsonapi_response(:category_assessment, category_assessment.attributes)
    end

    let(:make_request) { get edit_green_lanes_category_assessment_path(category_assessment) }

    it { is_expected.to have_http_status :success }
    it { is_expected.not_to include 'div.current-service' }
  end

  describe 'PATCH #update' do
    before do
      stub_api_request("/admin/green_lanes/category_assessments/#{category_assessment.id}")
        .and_return jsonapi_response(:category_assessment, category_assessment.attributes)

      stub_api_request("/admin/green_lanes/category_assessments/#{category_assessment.id}", :patch)
        .and_return patch_response
    end

    let :make_request do
      patch green_lanes_category_assessment_path(category_assessment),
            params: { category_assessment: category_assessment.attributes.merge(regulation_role: new_role) }
    end

    context 'with valid change' do
      let(:new_role) { '2' }
      let(:patch_response) { webmock_response :updated, "/admin/green_lanes/category_assessments/#{category_assessment.id}" }

      it { is_expected.to redirect_to green_lanes_category_assessments_path }
    end

    context 'with invalid change' do
      let(:new_role) { '' }
      let(:patch_response) { webmock_response :error, regulation_role: "can't be blank" }

      it { is_expected.to have_http_status :ok }
      it { is_expected.to have_attributes body: /can.+t be blank/ }
      it { is_expected.not_to include 'div.current-service' }
    end
  end

  describe 'POST #add_exemption' do
    before do
      stub_api_request("/admin/green_lanes/category_assessments/#{category_assessment.id}")
        .and_return jsonapi_response(:category_assessment, category_assessment.attributes)

      stub_api_request("/admin/green_lanes/category_assessments/#{category_assessment.id}/exemptions", :post).to_return \
        webmock_response(:success)
    end

    let :make_request do
      post add_exemption_green_lanes_category_assessment_path(category_assessment),
           params:
    end

    context 'with valid exemption id' do
      let(:params) { { cae: { exemption_id: 2 } } }

      it { is_expected.to redirect_to edit_green_lanes_category_assessment_path(id: category_assessment.id) }
    end

    context 'with empty exemption id' do
      let(:params) { { cae: { exemption_id: nil } } }

      it { is_expected.to have_http_status :ok }
      it { is_expected.to have_attributes body: /can.+t be blank/ }
      it { is_expected.not_to include 'div.current-service' }
    end
  end

  describe 'POST #remove_exemption' do
    before do
      stub_api_request("/admin/green_lanes/category_assessments/#{category_assessment.id}")
        .and_return jsonapi_response(:category_assessment, category_assessment.attributes)

      stub_api_request("/admin/green_lanes/category_assessments/#{category_assessment.id}/exemptions?exemption_id=2", :delete).to_return \
        webmock_response(:success)
    end

    let :make_request do
      delete remove_exemption_green_lanes_category_assessment_path(category_assessment),
             params:
    end

    context 'with valid exemption id' do
      let(:params) { { exemption_id: 2 } }

      it { is_expected.to redirect_to edit_green_lanes_category_assessment_path(id: category_assessment.id) }
    end

    context 'with empty exemption id' do
      let(:params) { { cae: { exemption_id: nil } } }

      it { is_expected.to have_http_status :ok }
      it { is_expected.to have_attributes body: /can.+t be blank/ }
      it { is_expected.not_to include 'div.current-service' }
    end
  end

  describe 'POST #add_measure' do
    before do
      stub_api_request("/admin/green_lanes/category_assessments/#{category_assessment.id}")
        .and_return jsonapi_response(:category_assessment, category_assessment.attributes)

      stub_api_request('/admin/green_lanes/measures', :post).to_return \
        webmock_response(:success)

      stub_api_request("/admin/green_lanes/category_assessments/#{category_assessment.id}/measures", :post).to_return \
        webmock_response(:success)
    end

    let(:measure) { build :green_lanes_measure, :with_category_assessment }

    let :make_request do
      post add_measure_green_lanes_category_assessment_path(category_assessment),
           params:
    end

    context 'with valid item' do
      let(:params) do
        { measure: { category_assessment_id: category_assessment.id,
                     goods_nomenclature_item_id: measure.goods_nomenclature_item_id,
                     productline_suffix: measure.productline_suffix } }
      end

      it { is_expected.to redirect_to edit_green_lanes_category_assessment_path(id: category_assessment.id) }
    end

    context 'with invalid item' do
      let(:params) do
        { measure: { category_assessment_id: category_assessment.id,
                     goods_nomenclature_item_id: nil,
                     productline_suffix: measure.productline_suffix } }
      end

      it { is_expected.to have_http_status :ok }
      it { is_expected.to have_attributes body: /can.+t be blank/ }
      it { is_expected.not_to include 'div.current-service' }
    end
  end

  describe 'DELETE #destroy' do
    before do
      stub_api_request("/admin/green_lanes/category_assessments/#{category_assessment.id}")
        .and_return jsonapi_response(:category_assessment, category_assessment.attributes)

      stub_api_request("/admin/green_lanes/category_assessments/#{category_assessment.id}", :delete)
        .and_return webmock_response :no_content
    end

    let(:make_request) { delete green_lanes_category_assessment_path(category_assessment) }

    it { is_expected.to redirect_to green_lanes_category_assessments_path }
  end
end
