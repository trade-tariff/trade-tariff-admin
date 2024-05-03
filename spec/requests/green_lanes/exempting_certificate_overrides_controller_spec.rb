RSpec.describe GreenLanes::ExemptingCertificateOverridesController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:exempting_certificate_override) { build :exempting_certificate_override }
  let(:create_user) { create :user, permissions: ['signin', 'HMRC Editor'] }

  before do
    allow(TradeTariffAdmin::ServiceChooser).to receive(:service_choice).and_return 'xi'
  end

  describe 'GET #index' do
    before do
      stub_api_request('/admin/green_lanes/exempting_certificate_overrides?page=1', backend: 'xi').and_return \
        jsonapi_response :exempting_certificate_overrides, attributes_for_list(:exempting_certificate_override, 3)
    end

    let(:make_request) { get green_lanes_exempting_certificate_overrides_path }

    it { is_expected.to have_http_status :success }
    it { is_expected.not_to include 'div.current-service' }
  end

  describe 'GET #new' do
    let(:make_request) { get new_green_lanes_exempting_certificate_override_path }

    it { is_expected.to have_http_status :ok }
    it { is_expected.not_to include 'div.current-service' }
  end

  describe 'POST #create' do
    before do
      stub_api_request('/admin/green_lanes/exempting_certificate_overrides', :post).to_return create_response
    end

    let :make_request do
      post green_lanes_exempting_certificate_overrides_path,
           params: { exempting_certificate_override: eco_params }
    end

    context 'with valid item' do
      let(:eco_params) { exempting_certificate_override.attributes.without(:id) }
      let(:create_response) { webmock_response(:created, exempting_certificate_override.attributes) }

      it { is_expected.to redirect_to green_lanes_exempting_certificate_overrides_path }
    end

    context 'with invalid item' do
      let(:eco_params) { exempting_certificate_override.attributes.without(:id, :certificate_type_code) }
      let(:create_response) { webmock_response(:error, certificate_type_code: "can't be blank'") }

      it { is_expected.to have_http_status :ok }
      it { is_expected.to have_attributes body: /can.+t be blank/ }
      it { is_expected.not_to include 'div.current-service' }
    end
  end
end
