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

  describe 'GET #new' do
    let(:make_request) { get new_green_lanes_exemption_path }

    it { is_expected.to have_http_status :ok }
    it { is_expected.not_to include 'div.current-service' }
  end

  describe 'POST #create' do
    before do
      stub_api_request('/admin/green_lanes/exemptions', :post).to_return create_response
    end

    let :make_request do
      post green_lanes_exemptions_path,
           params: { exemption: ex_params }
    end

    context 'with valid item' do
      let(:ex_params) { exemption.attributes.without(:id) }
      let(:create_response) { webmock_response(:created, exemption.attributes) }

      it { is_expected.to redirect_to green_lanes_exemptions_path }
    end

    context 'with invalid item' do
      let(:ex_params) { exemption.attributes.without(:id, :code) }
      let(:create_response) { webmock_response(:error, code: "can't be blank'") }

      it { is_expected.to have_http_status :ok }
      it { is_expected.to have_attributes body: /can.+t be blank/ }
      it { is_expected.not_to include 'div.current-service' }
    end
  end

  describe 'GET #edit' do
    before do
      stub_api_request("/admin/green_lanes/exemptions/#{exemption.id}")
        .and_return jsonapi_response(:exemption, exemption.attributes)
    end

    let(:make_request) { get edit_green_lanes_exemption_path(exemption) }

    it { is_expected.to have_http_status :success }
    it { is_expected.not_to include 'div.current-service' }
  end

  describe 'PATCH #update' do
    before do
      stub_api_request("/admin/green_lanes/exemptions/#{exemption.id}")
        .and_return jsonapi_response(:exemption, exemption.attributes)

      stub_api_request("/admin/green_lanes/exemptions/#{exemption.id}", :patch)
        .and_return patch_response
    end

    let :make_request do
      patch green_lanes_exemption_path(exemption),
            params: { exemption: exemption.attributes.merge(description: new_desc) }
    end

    context 'with valid change' do
      let(:new_desc) { 'New description' }
      let(:patch_response) { webmock_response :updated, "/admin/green_lanes/exemptions/#{exemption.id}" }

      it { is_expected.to redirect_to green_lanes_exemptions_path }
    end

    context 'with invalid change' do
      let(:new_desc) { nil }
      let(:patch_response) { webmock_response :error, description: "can't be blank" }

      it { is_expected.to have_http_status :ok }
      it { is_expected.to have_attributes body: /can.+t be blank/ }
      it { is_expected.not_to include 'div.current-service' }
    end
  end

  describe 'DELETE #destroy' do
    before do
      stub_api_request("/admin/green_lanes/exemptions/#{exemption.id}")
        .and_return jsonapi_response(:exemption, exemption.attributes)

      stub_api_request("/admin/green_lanes/exemptions/#{exemption.id}", :delete)
        .and_return webmock_response :no_content
    end

    let(:make_request) { delete green_lanes_exemption_path(exemption) }

    it { is_expected.to redirect_to green_lanes_exemptions_path }
  end
end
