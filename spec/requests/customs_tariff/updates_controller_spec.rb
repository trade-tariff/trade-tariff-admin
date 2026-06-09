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

  let(:updates_list_response) do
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: [
          {
            type: "customs_tariff_update",
            id: update_version,
            attributes: update_attributes,
          },
        ],
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
      stub_api_request("/customs_tariff_updates/#{update_version}/sections_summary")
        .and_return(
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: { data: [] }.to_json,
        )
      stub_api_request("/customs_tariff_updates").and_return(updates_list_response)
    end

    it { is_expected.to have_http_status(:ok) }
    it { is_expected.to render_template(:show) }

    it "renders the compare form" do
      make_request
      expect(response.body).to include(customs_tariff_update_comparison_path(update_version))
    end

    context "when a previous version exists in the updates list" do
      before do
        stub_api_request("/customs_tariff_updates/#{update_version}").and_return(update_response)
        stub_api_request("/customs_tariff_updates/#{update_version}/sections_summary").and_return(
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: { data: [] }.to_json,
        )
        stub_api_request("/customs_tariff_updates").and_return(
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: {
            data: [
              { type: "customs_tariff_update", id: update_version, attributes: update_attributes },
              {
                type: "customs_tariff_update",
                id: "1.30",
                attributes: update_attributes.merge("version" => "1.30", "status" => "pending", "validity_start_date" => "2025-12-01"),
              },
            ],
          }.to_json,
        )
        get customs_tariff_update_path(update_version)
      end

      it "displays the baseline version in explanatory text" do
        expect(response.body).to include("Comparing notes against version 1.30")
      end
    end

    context "when a section summary has absent section note status" do
      before do
        stub_api_request("/customs_tariff_updates/#{update_version}").and_return(update_response)
        stub_api_request("/customs_tariff_updates/#{update_version}/sections_summary").and_return(
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: {
            data: [
              {
                type: "section_summary",
                id: "3",
                attributes: {
                  "section_id" => 3,
                  "section_title" => "Section 3",
                  "position" => 3,
                  "section_note_id" => nil,
                  "section_note_status" => "absent",
                  "chapter_notes_total" => 0,
                  "chapter_notes_changed" => 0,
                },
              },
            ],
          }.to_json,
        )
        stub_api_request("/customs_tariff_updates").and_return(updates_list_response)
        get customs_tariff_update_path(update_version)
      end

      it "renders an Add link for the absent section", :aggregate_failures do
        expect(response.body).to include(">Add<")
        expect(response.body).to include(
          new_customs_tariff_update_section_note_path(update_version, section_id: 3),
        )
      end
    end
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

      it { is_expected.to redirect_to(customs_tariff_updates_path) }

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

  describe "POST #reimport" do
    let(:make_request) do
      post reimport_customs_tariff_update_path(update_version)
    end

    context "when the backend accepts the reimport" do
      before do
        stub_api_request("/customs_tariff_updates/#{update_version}")
          .and_return(update_response)
        stub_api_request("/customs_tariff_updates/#{update_version}/reimport", :post)
          .and_return(
            status: 202,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: "",
          )
      end

      it { is_expected.to redirect_to(customs_tariff_updates_path) }

      it "sets a success flash notice" do
        make_request
        expect(session.dig("flash", "flashes", "notice")).to eq("Re-import queued.")
      end
    end

    context "when the backend returns 404" do
      before do
        stub_api_request("/customs_tariff_updates/#{update_version}")
          .and_return(update_response)
        stub_api_request("/customs_tariff_updates/#{update_version}/reimport", :post)
          .and_return(status: 404, body: "", headers: { "content-type" => "application/json; charset=utf-8" })
      end

      it { is_expected.to redirect_to(customs_tariff_updates_path) }

      it "sets an alert flash" do
        make_request
        expect(session.dig("flash", "flashes", "alert")).to eq("Update could not be found.")
      end
    end
  end
end
