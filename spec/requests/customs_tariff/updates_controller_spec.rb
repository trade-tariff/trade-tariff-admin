RSpec.describe CustomsTariff::UpdatesController, type: :request do
  subject(:rendered_page) { make_request && response }

  before { TradeTariffAdmin::ServiceChooser.service_choice = "uk" }

  let(:update_version) { "1.31" }

  let(:update_attributes) do
    {
      "version" => update_version,
      "status" => "pending",
      "validity_start_date" => "2026-01-01",
      "validity_end_date" => nil,
      "source_url" => "https://example.com/document.pdf",
      "document_created_on" => "2026-01-01",
      "created_at" => "2026-01-01T00:00:00Z",
      "updated_at" => "2026-01-01T00:00:00Z",
    }
  end

  let(:update_response) do
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: {
          type: "customs_tariff_update",
          id: update_version,
          attributes: update_attributes,
        },
      }.to_json,
    }
  end

  describe "GET #index" do
    let(:make_request) { get customs_tariff_updates_path }

    before do
      stub_api_request("/customs_tariff_updates")
        .and_return(
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: {
            data: [{ type: "customs_tariff_update", id: update_version, attributes: update_attributes }],
          }.to_json,
        )
    end

    it { is_expected.to have_http_status(:ok) }
    it { is_expected.to render_template(:index) }
  end

  describe "GET #show" do
    let(:make_request) { get customs_tariff_update_path(update_version) }

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
      stub_api_request("/customs_tariff_updates/#{update_version}/section_notes")
        .and_return(
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: { data: [] }.to_json,
        )
    end

    it { is_expected.to have_http_status(:ok) }
    it { is_expected.to render_template(:show) }
  end

  describe "PATCH #update_status" do
    context "when the backend accepts the status change" do
      let(:make_request) do
        patch update_status_customs_tariff_update_path(update_version), params: { status: "approved" }
      end

      before do
        stub_api_request("/customs_tariff_updates/#{update_version}")
          .and_return(update_response)
        stub_api_request("/customs_tariff_updates/#{update_version}/status", :patch)
          .and_return(
            status: 200,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: {}.to_json,
          )
      end

      it { is_expected.to redirect_to(customs_tariff_update_path(update_version)) }

      it "sets a success flash notice" do
        make_request
        expect(session.dig("flash", "flashes", "notice")).to eq("Status updated to approved.")
      end
    end

    context "when the backend rejects the status change" do
      let(:make_request) do
        patch update_status_customs_tariff_update_path(update_version), params: { status: "approved" }
      end

      before do
        stub_api_request("/customs_tariff_updates/#{update_version}")
          .and_return(update_response)
        stub_api_request("/customs_tariff_updates/#{update_version}/status", :patch)
          .and_return(
            status: 422,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: { errors: [{ detail: "Version is already approved" }] }.to_json,
          )
      end

      it { is_expected.to redirect_to(customs_tariff_update_path(update_version)) }

      it "sets a flash alert containing the backend error detail" do
        make_request
        expect(session.dig("flash", "flashes", "alert")).to eq("Could not update status: Version is already approved")
      end
    end
  end
end
