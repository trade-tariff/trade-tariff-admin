RSpec.describe TariffUpdatesController, skip: 'TODO: Fix intermittent failures' do
  subject(:rendered_page) { create_user && make_request && response }

  let(:create_user) { create :user, permissions: ['signin', 'HMRC Admin'] }

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

  describe 'POST #clear_cache' do
    context 'when the API /clear_cache succeeds' do
      before do
        create_user
        stub_api_request('/admin/clear_caches', :post).to_return(status: 200, body: '', headers: {})
      end

      it 'returns success' do
        post '/tariff_updates/clear_cache'

        expect(response).to redirect_to(tariff_updates_path) # it stays on the same page
        expect(flash[:notice]).to eq('ClearCache was scheduled')
      end
    end

    context 'when the API /clear_caches fails' do
      before do
        create_user
        stub_api_request('/admin/clear_caches', :post).to_return(status: 422, body: '', headers: {})
      end

      it 'displays an error message' do
        post '/tariff_updates/clear_cache'

        expect(response).to redirect_to(tariff_updates_path) # it stays on the same page
        expect(flash[:alert]).to include('Unexpected error:')
      end
    end

    context 'when unauthorised clear_cache' do
      let(:create_user) { create :user, permissions: %w[] }
      let(:make_request) { get clear_cache_tariff_updates_path }

      it { is_expected.to have_http_status :forbidden }
      it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
    end
  end

  describe 'POST #download' do
    context 'when the API /download succeeds' do
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

    context 'when the API /downloads fails' do
      before do
        create_user
        stub_api_request('/admin/downloads', :post).to_return(status: 422, body: '', headers: {})
      end

      it 'displays an error message' do
        post '/tariff_updates/download'

        expect(response).to redirect_to(tariff_updates_path) # it stays on the same page
        expect(flash[:alert]).to include('Unexpected error:')
      end
    end

    context 'when unauthorised download' do
      let(:create_user) { create :user, permissions: %w[] }
      let(:make_request) { get download_tariff_updates_path }

      it { is_expected.to have_http_status :forbidden }
      it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
    end
  end

  describe 'POST #apply' do
    context 'when the API /applies succeeds' do
      before do
        create_user
        stub_api_request('/admin/applies', :post).to_return(status: 200, body: '', headers: {})
      end

      it 'returns success' do
        post '/tariff_updates/apply'

        expect(response).to redirect_to(tariff_updates_path) # it stays on the same page
        expect(flash[:notice]).to eq('Apply was scheduled')
      end
    end

    context 'when the API /applies fails', skip: 'TODO: Fix intermittent failures' do
      before do
        create_user
        stub_api_request('/admin/applies', :post).to_return(status: 422, body: '', headers: {})
      end

      it 'displays an error message' do
        post '/tariff_updates/apply'

        expect(response).to redirect_to(tariff_updates_path) # it stays on the same page
        expect(flash[:alert]).to include('Unexpected error:')
      end
    end

    context 'when unauthorised apply' do
      let(:create_user) { create :user, permissions: %w[] }
      let(:make_request) { get apply_tariff_updates_path }

      it { is_expected.to have_http_status :forbidden }
      it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
    end
  end
end
