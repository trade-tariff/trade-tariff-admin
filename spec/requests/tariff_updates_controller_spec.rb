RSpec.describe TariffUpdatesController do
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

  describe 'POST #download' do
    context 'when authorised download' do
      before do
        create_user
        stub_api_request('/admin/downloads', :post).to_return(status: 200, body: "", headers: {})
      end

      it "returns success" do
        post '/tariff_updates/download'

        expect(response.status).to eq(302)
        expect(flash[:notice]).to eq("Download was scheduled")
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
    context 'when authorised apply' do
      before do
        create_user
        stub_api_request('/admin/applies', :post).to_return(status: 200, body: "", headers: {})
      end

      it "returns success" do
        post '/tariff_updates/apply'

        expect(response.status).to eq(302)
        expect(flash[:notice]).to eq("Apply was scheduled")
      end
    end

    context 'when unauthorised download' do
      let(:create_user) { create :user, permissions: %w[] }
      let(:make_request) { get apply_tariff_updates_path }

      it { is_expected.to have_http_status :forbidden }
      it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
    end
  end
end
