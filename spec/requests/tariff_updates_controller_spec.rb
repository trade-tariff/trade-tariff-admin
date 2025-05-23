RSpec.describe TariffUpdatesController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:create_user) { create :user, permissions: ['signin', 'HMRC Admin'] }

  describe 'GET #index' do
    before do
      stub_api_request('/updates?page=1').and_return \
        jsonapi_response :tariff_updates, attributes_for_list(:update, 3)
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

  describe 'POST #download' do
    before do
      create_user
      stub_api_request('/admin/downloads', :post).to_return(status: 200, body: '', headers: {})
    end

    it 'displays success message' do
      post '/tariff_updates/download'

      expect(response).to redirect_to(tariff_updates_path) # it stays on the same page
      expect(flash[:notice]).to eq('Download was scheduled')
    end
  end

  describe 'POST #apply_and_clear_cache' do
    before do
      create_user
      stub_api_request('/admin/applies', :post).to_return(status: 200, body: '', headers: {})
    end

    it 'returns success' do
      post '/tariff_updates/apply_and_clear_cache'

      expect(response).to redirect_to(tariff_updates_path)
      expect(flash[:notice]).to eq('Apply & ClearCache was scheduled')
    end
  end
end
