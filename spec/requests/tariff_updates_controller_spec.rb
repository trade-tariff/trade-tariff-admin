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

  def stub_tariff_update_command(path, response)
    TradeTariffAdmin::ServiceChooser.service_choice = "uk"
    stub_api_request(path, :post).to_return(response)
  end

  def unprocessable_tariff_update_response(detail)
    {
      status: 422,
      headers: { "content-type" => "application/json" },
      body: {
        errors: [
          {
            status: "422",
            detail:,
            source: { pointer: "/data/attributes/base" },
          },
        ],
      }.to_json,
    }
  end

  def tariff_update_server_error_response
    {
      status: 500,
      headers: { "content-type" => "application/json" },
      body: { error: "Internal Server Error" }.to_json,
    }
  end

  def unexpected_tariff_update_alert(path)
    "Unexpected error: the server responded with status 500 for POST #{TradeTariffAdmin::ServiceChooser.uk_host}#{path}"
  end

  def tariff_update_command_payload(type, attributes = nil)
    data = { "type" => type }
    data["attributes"] = attributes if attributes
    { "data" => data }
  end

  def tariff_update_command_request(path, payload)
    a_request(:post, %r{#{Regexp.escape(path)}\z}).with(body: payload)
  end

  def cds_notification_filename
    "2026-04-01_TGB22037.xml"
  end

  def cds_notification_payload
    tariff_update_command_payload(
      "cds_update_notification",
      "filename" => cds_notification_filename,
    )
  end

  def post_cds_update_notification
    post "/tariff_updates/resend_cds_update_notification",
         params: { cds_update_notification: { filename: cds_notification_filename } }
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

  context "when using no-auth synthetic user" do
    include_context "with no-auth synthetic user"

    it "shows the rollback link on the updates page", :aggregate_failures do
      stub_tariff_updates_index([rollbackable_update])

      get tariff_updates_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Rollback to 2026-04-01")
    end

    it "shows the direct update download link", :aggregate_failures do
      update_id = "2026-04-01_TGB22037"
      stub_tariff_update_show(update_id, rollbackable_update)

      get tariff_update_path(update_id)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("https://example.com/2026-04-01_TGB22037.xml")
    end

    it "can schedule a download" do
      TradeTariffAdmin::ServiceChooser.service_choice = "uk"
      stub_api_request("/admin/downloads", :post).to_return(status: 200, body: "", headers: {})

      post "/tariff_updates/download"

      expect(response).to redirect_to(tariff_updates_path)
    end

    it "can apply updates and clear cache" do
      TradeTariffAdmin::ServiceChooser.service_choice = "uk"
      stub_api_request("/admin/applies", :post).to_return(status: 200, body: "", headers: {})

      post "/tariff_updates/apply_and_clear_cache"

      expect(response).to redirect_to(tariff_updates_path)
    end

    it "can resend CDS update notifications" do
      stub_api_request("/admin/cds_update_notifications", :post).to_return(status: 200, body: "", headers: {})

      post "/tariff_updates/resend_cds_update_notification", params: { cds_update_notification: { filename: "filename" } }

      expect(response).to redirect_to(tariff_updates_path)
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

    it "shows review inserts and direct update download links without destructive actions", :aggregate_failures do
      stub_tariff_updates_index([rollbackable_update])

      get tariff_updates_path

      expect(response.body).to include("Review inserts", "Download 2026-04-01_TGB22037.xml")
      expect(response.body).not_to include("Apply & Clear Caches", "Resend CDS Update email")
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

      it "shows the download link" do
        make_request

        expect(response.body).to include("https://example.com/2026-04-01_TGB22037.xml")
      end
    end

    context "when auditor" do
      let(:current_user) { create(:user, :auditor) }

      it "shows the download link" do
        make_request

        expect(response.body).to include("https://example.com/2026-04-01_TGB22037.xml")
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

    context "when the backend returns 422" do
      before do
        stub_tariff_update_command(
          "/admin/downloads",
          unprocessable_tariff_update_response("Download could not be scheduled"),
        )
        post "/tariff_updates/download"
      end

      it "responds with found" do
        expect(response).to have_http_status(:found)
      end

      it "redirects to the updates page" do
        expect(response).to redirect_to(tariff_updates_path)
      end

      it "keeps the scheduled notice" do
        expect(flash[:notice]).to eq("Download was scheduled")
      end

      it "does not set an alert" do
        expect(flash[:alert]).to be_nil
      end

      it "stores the backend error" do
        expect(assigns(:download).errors[:base]).to eq(["Download could not be scheduled"])
      end

      it "posts the download payload" do
        expect(tariff_update_command_request("/admin/downloads", tariff_update_command_payload("download"))).to have_been_made.once
      end
    end

    context "when the backend returns 500" do
      before do
        stub_tariff_update_command("/admin/downloads", tariff_update_server_error_response)
        post "/tariff_updates/download"
      end

      it "responds with found" do
        expect(response).to have_http_status(:found)
      end

      it "redirects to the updates page" do
        expect(response).to redirect_to(tariff_updates_path)
      end

      it "sets the unexpected error alert" do
        expect(flash[:alert]).to eq(unexpected_tariff_update_alert("/admin/downloads"))
      end

      it "does not set a notice" do
        expect(flash[:notice]).to be_nil
      end

      it "posts the download payload" do
        expect(tariff_update_command_request("/admin/downloads", tariff_update_command_payload("download"))).to have_been_made.once
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

    context "when the backend returns 422" do
      before do
        stub_tariff_update_command(
          "/admin/applies",
          unprocessable_tariff_update_response("Apply could not be scheduled"),
        )
        post "/tariff_updates/apply_and_clear_cache"
      end

      it "responds with found" do
        expect(response).to have_http_status(:found)
      end

      it "redirects to the updates page" do
        expect(response).to redirect_to(tariff_updates_path)
      end

      it "keeps the scheduled notice" do
        expect(flash[:notice]).to eq("Apply & ClearCache was scheduled")
      end

      it "does not set an alert" do
        expect(flash[:alert]).to be_nil
      end

      it "stores the backend error" do
        expect(assigns(:apply).errors[:base]).to eq(["Apply could not be scheduled"])
      end

      it "posts the apply payload" do
        expect(tariff_update_command_request("/admin/applies", tariff_update_command_payload("apply"))).to have_been_made.once
      end
    end

    context "when the backend returns 500" do
      before do
        stub_tariff_update_command("/admin/applies", tariff_update_server_error_response)
        post "/tariff_updates/apply_and_clear_cache"
      end

      it "responds with found" do
        expect(response).to have_http_status(:found)
      end

      it "redirects to the updates page" do
        expect(response).to redirect_to(tariff_updates_path)
      end

      it "sets the unexpected error alert" do
        expect(flash[:alert]).to eq(unexpected_tariff_update_alert("/admin/applies"))
      end

      it "does not set a notice" do
        expect(flash[:notice]).to be_nil
      end

      it "posts the apply payload" do
        expect(tariff_update_command_request("/admin/applies", tariff_update_command_payload("apply"))).to have_been_made.once
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

    context "when the backend returns 422" do
      before do
        stub_tariff_update_command(
          "/admin/cds_update_notifications",
          unprocessable_tariff_update_response("CDS update notification could not be scheduled"),
        )
        post_cds_update_notification
      end

      it "responds with found" do
        expect(response).to have_http_status(:found)
      end

      it "redirects to the updates page" do
        expect(response).to redirect_to(tariff_updates_path)
      end

      it "keeps the scheduled notice" do
        expect(flash[:notice]).to eq("CDS Updates notification was scheduled")
      end

      it "does not set an alert" do
        expect(flash[:alert]).to be_nil
      end

      it "stores the backend error" do
        expect(assigns(:cds_update).errors[:base]).to eq(["CDS update notification could not be scheduled"])
      end

      it "posts the notification payload" do
        expect(tariff_update_command_request("/admin/cds_update_notifications", cds_notification_payload)).to have_been_made.once
      end
    end

    context "when the backend returns 500" do
      before do
        stub_tariff_update_command("/admin/cds_update_notifications", tariff_update_server_error_response)
        post_cds_update_notification
      end

      it "responds with found" do
        expect(response).to have_http_status(:found)
      end

      it "redirects to the updates page" do
        expect(response).to redirect_to(tariff_updates_path)
      end

      it "sets the unexpected error alert" do
        expect(flash[:alert]).to eq(unexpected_tariff_update_alert("/admin/cds_update_notifications"))
      end

      it "does not set a notice" do
        expect(flash[:notice]).to be_nil
      end

      it "posts the notification payload" do
        expect(tariff_update_command_request("/admin/cds_update_notifications", cds_notification_payload)).to have_been_made.once
      end
    end
  end
end
