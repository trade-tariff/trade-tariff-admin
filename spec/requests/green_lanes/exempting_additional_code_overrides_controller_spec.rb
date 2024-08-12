RSpec.describe GreenLanes::ExemptingAdditionalCodeOverridesController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:exempting_additional_code_override) { build :exempting_additional_code_override }
  let(:create_user) { create :user, permissions: ['signin', 'HMRC Editor'] }

  before do
    allow(TradeTariffAdmin::ServiceChooser).to receive(:service_choice).and_return 'xi'
  end

  describe 'GET #new' do
    let(:make_request) { get new_green_lanes_exempting_additional_code_override_path }

    it { is_expected.to have_http_status :ok }
    it { is_expected.not_to include 'div.current-service' }
  end

  describe 'POST #create' do
    before do
      stub_api_request('/admin/green_lanes/exempting_additional_code_overrides', :post).to_return create_response
    end

    let :make_request do
      post green_lanes_exempting_additional_code_overrides_path,
           params: { exempting_additional_code_override: eaco_params }
    end

    context 'with valid item' do
      let(:eaco_params) { exempting_additional_code_override.attributes.without(:id) }
      let(:create_response) { webmock_response(:created, exempting_additional_code_override.attributes) }

      it { is_expected.to redirect_to green_lanes_exempting_overrides_path }
    end

    context 'with invalid item' do
      let(:eaco_params) { exempting_additional_code_override.attributes.without(:id, :additional_code_type_id) }
      let(:create_response) { webmock_response(:error, additional_code_type_id: "can't be blank'") }

      it { is_expected.to have_http_status :ok }
      it { is_expected.to have_attributes body: /can.+t be blank/ }
      it { is_expected.not_to include 'div.current-service' }
    end
  end

  describe 'DELETE #destroy' do
    before do
      stub_api_request("/admin/green_lanes/exempting_additional_code_overrides/#{exempting_additional_code_override.id}")
        .and_return jsonapi_response(:exempting_additional_code_override, exempting_additional_code_override.attributes)

      stub_api_request("/admin/green_lanes/exempting_additional_code_overrides/#{exempting_additional_code_override.id}", :delete)
        .and_return webmock_response :no_content
    end

    let(:make_request) { delete green_lanes_exempting_additional_code_override_path(exempting_additional_code_override) }

    it { is_expected.to redirect_to green_lanes_exempting_overrides_path }
  end
end