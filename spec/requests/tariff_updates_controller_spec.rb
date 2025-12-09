RSpec.describe TariffUpdatesController do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  describe "GET #index" do
    before do
      stub_api_request("/updates?page=1").and_return \
        jsonapi_response :tariff_updates, attributes_for_list(:update, 3)
    end

    let(:make_request) { get tariff_updates_path }

    it { is_expected.to have_http_status :success }
  end

  context "when unauthenticated" do
    let(:authenticate_user) { false }
    let(:extra_session) { {} }

    it "redirects to the configured authentication provider" do
      expect_unauthenticated_redirect(-> { get tariff_updates_path })
    end
  end

  context "when unauthorised" do
    let(:current_user) { create(:user, permissions: %w[]) }

    let(:make_request) { get tariff_updates_path }

    it { is_expected.to have_http_status :forbidden }
    it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
  end

  describe "POST #download" do
    before do
      TradeTariffAdmin::ServiceChooser.service_choice = "uk"
      stub_api_request("/admin/downloads", :post).to_return(status: 200, body: "", headers: {})
    end

    it "displays success message", :aggregate_failures do
      post "/tariff_updates/download"

      expect(response).to redirect_to(tariff_updates_path) # it stays on the same page
      expect(flash[:notice]).to eq("Download was scheduled")
    end
  end

  describe "POST #apply_and_clear_cache" do
    before do
      TradeTariffAdmin::ServiceChooser.service_choice = "uk"
      stub_api_request("/admin/applies", :post).to_return(status: 200, body: "", headers: {})
    end

    it "returns success", :aggregate_failures do
      post "/tariff_updates/apply_and_clear_cache"

      expect(response).to redirect_to(tariff_updates_path)
      expect(flash[:notice]).to eq("Apply & ClearCache was scheduled")
    end
  end

  describe "POST #resend_cds_update_notification" do
    before do
      stub_api_request("/admin/cds_update_notifications", :post).to_return(status: 200, body: "", headers: {})
    end

    let(:make_request) { post "/tariff_updates/resend_cds_update_notification", params: { cds_update_notification: { filename: "filename" } } }

    it { is_expected.to redirect_to(tariff_updates_path) }

    it "displays success message" do
      rendered_page
      expect(flash[:notice]).to eq("CDS Updates notification was scheduled")
    end
  end
end
