RSpec.describe TariffUpdatesController do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"
  let(:current_user) { create(:user, :superadmin) }
  let(:rollbackable_update) do
    attributes_for(
      :update,
      state: "A",
      issue_date: "2026-04-01",
      filename: "2026-04-01_TGB22037.xml",
      file_presigned_url: "https://example.com/2026-04-01_TGB22037.xml",
    )
  end

  def stub_tariff_updates_index(updates = attributes_for_list(:update, 3))
    stub_api_request("/updates?page=1").and_return \
      jsonapi_response(:tariff_updates, updates)
  end

  def stub_tariff_update_show(update_id, update_attributes)
    stub_api_request("/updates/#{update_id}").and_return \
      jsonapi_response(:update, update_attributes)
  end

  describe "GET #index" do
    before { stub_tariff_updates_index }

    let(:make_request) { get tariff_updates_path }

    it { is_expected.to have_http_status :success }

    it "shows the rollback link to superadmin when applicable" do
      stub_tariff_updates_index([rollbackable_update])

      get tariff_updates_path

      expect(response.body).to include("Rollback to 2026-04-01")
    end
  end

  context "when unauthenticated" do
    let(:authenticate_user) { false }
    let(:extra_session) { {} }

    it "redirects to the configured authentication provider" do
      expect_unauthenticated_redirect(-> { get tariff_updates_path })
    end
  end

  context "when unauthorised" do
    let(:current_user) { create(:user, :guest) }

    let(:make_request) { get tariff_updates_path }

    it { is_expected.to have_http_status :forbidden }
    it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
  end

  context "when technical operator" do
    let(:current_user) { create(:user, :technical_operator) }
    let(:make_request) { get tariff_updates_path }

    before { stub_tariff_updates_index }

    it { is_expected.to have_http_status :success }

    it "does not show the rollback link on the updates page" do
      stub_tariff_updates_index([rollbackable_update])

      get tariff_updates_path

      expect(response.body).not_to include("Rollback to 2026-04-01")
    end
  end

  context "when auditor" do
    let(:current_user) { create(:user, :auditor) }
    let(:make_request) { get tariff_updates_path }

    before { stub_tariff_updates_index }

    it { is_expected.to have_http_status :success }

    it "does not show the rollback link on the updates page" do
      stub_tariff_updates_index([rollbackable_update])

      get tariff_updates_path

      expect(response.body).not_to include("Rollback to 2026-04-01")
    end
  end

  describe "GET #show" do
    let(:update_id) { "2026-04-01_TGB22037" }
    let(:make_request) { get tariff_update_path(update_id) }

    before do
      stub_tariff_update_show(update_id, rollbackable_update)
    end

    it { is_expected.to have_http_status :success }

    it "shows the download link to superadmin" do
      make_request

      expect(response.body).to include("https://example.com/2026-04-01_TGB22037.xml")
    end

    context "when technical operator" do
      let(:current_user) { create(:user, :technical_operator) }

      it "hides the download link" do
        make_request

        expect(response.body).not_to include("https://example.com/2026-04-01_TGB22037.xml")
      end
    end

    context "when auditor" do
      let(:current_user) { create(:user, :auditor) }

      it "hides the download link" do
        make_request

        expect(response.body).not_to include("https://example.com/2026-04-01_TGB22037.xml")
      end
    end
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

    context "when technical operator" do
      let(:current_user) { create(:user, :technical_operator) }

      it "returns forbidden" do
        post "/tariff_updates/download"

        expect(response).to have_http_status(:forbidden)
      end
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

    context "when technical operator" do
      let(:current_user) { create(:user, :technical_operator) }

      it "returns forbidden" do
        post "/tariff_updates/apply_and_clear_cache"

        expect(response).to have_http_status(:forbidden)
      end
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

    context "when technical operator" do
      let(:current_user) { create(:user, :technical_operator) }

      it "returns forbidden" do
        post "/tariff_updates/resend_cds_update_notification", params: { cds_update_notification: { filename: "filename" } }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
