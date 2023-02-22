RSpec.describe TariffUpdatesController do
  subject(:rendered_page) { create_user && make_request && response }
  
  let(:create_user) { create :user, permissions: ['signin', 'Full access'] }

  describe 'GET #index' do
    before do
      stub_api_request('/updates?page=1').and_return \
        jsonapi_response :tariff_updates, attributes_for_list(:tariff_update, 3)
    end

    let(:make_request) { get tariff_updates_path }

    it { is_expected.to have_http_status :success }
  end

  context 'when unauthenticated' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('GDS_SSO_MOCK_INVALID').and_return 'true'
    end

    let(:make_request) { get tariff_updates_path }

    it { is_expected.to redirect_to '/auth/gds' }
  end

  context 'when unauthorised' do
    let(:create_user) { create :user, permissions: %w[] }
    let(:make_request) { get tariff_updates_path }

    it { is_expected.to have_http_status :forbidden }
    it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
  end
end
