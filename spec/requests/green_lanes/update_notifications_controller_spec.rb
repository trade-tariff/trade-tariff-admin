RSpec.describe GreenLanes::ExemptionsController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:update) { build :update_notification }
  let(:create_user) { create :user, permissions: ['signin', 'HMRC Editor'] }

  before do
    allow(TradeTariffAdmin::ServiceChooser).to receive(:service_choice).and_return 'xi'
  end

  describe 'GET #index' do
    before do
      stub_api_request('/admin/green_lanes/update_notifications?page=1', backend: 'xi').and_return \
        jsonapi_response :update, attributes_for_list(:update_notification, 3)
    end

    let(:make_request) { get green_lanes_update_notifications_path }

    it { is_expected.to have_http_status :success }
    it { is_expected.not_to include 'div.current-service' }
  end

  describe 'GET #edit' do
    before do
      stub_api_request("/admin/green_lanes/update_notifications/#{update.id}")
        .and_return jsonapi_response(:update, update.attributes)
    end

    let(:make_request) { get edit_green_lanes_update_notification_path(update) }

    it { is_expected.to have_http_status :success }
    it { is_expected.not_to include 'div.current-service' }
  end
end
