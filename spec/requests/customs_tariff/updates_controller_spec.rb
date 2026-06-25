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
        .with(query: { "page" => "1" })
        .and_return(
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: {
            data: [{ type: "customs_tariff_update", id: update_version, attributes: update_attributes }],
            meta: {
              pagination: {
                page: 1,
                per_page: 20,
                total_count: 1,
              },
            },
          }.to_json,
        )
    end

    it { is_expected.to have_http_status(:ok) }
    it { is_expected.to render_template(:index) }

    it "does not render file-level status" do
      make_request

      expect(response.body).not_to include("Pending")
    end

    context "when more updates exist than fit on one page" do
      let(:make_request) { get customs_tariff_updates_path, params: { page: 2 } }

      before do
        stub_api_request("/customs_tariff_updates")
          .with(query: { "page" => "2" })
          .and_return(
            status: 200,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: {
              data: [
                {
                  type: "customs_tariff_update",
                  id: "9.26",
                  attributes: update_attributes.merge("version" => "9.26"),
                },
              ],
              meta: {
                pagination: {
                  page: 2,
                  per_page: 25,
                  total_count: 26,
                },
              },
            }.to_json,
          )
      end

      it "paginates the updates table", :aggregate_failures do
        make_request

        expect(response.body).to include("9.26")
        expect(response.body).not_to include("9.01")
        expect(response.body).to include("govuk-pagination")
      end

      it "requests the selected page from the backend" do
        make_request

        expect(a_request(:get, %r{/admin/customs_tariff_updates}).with(query: { "page" => "2" }))
          .to have_been_made
      end
    end
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
      stub_api_request("/sections").and_return(
        status: 200,
        headers: { "content-type" => "application/json; charset=utf-8" },
        body: { data: [] }.to_json,
      )
    end

    it { is_expected.to have_http_status(:ok) }
    it { is_expected.to render_template(:show) }

    it "renders the compare form" do
      make_request
      expect(response.body).to include(customs_tariff_update_comparison_path(update_version))
    end

    it "does not render whole-file approval controls", :aggregate_failures do
      make_request

      expect(response.body).not_to include("Approve")
      expect(response.body).not_to include("Reject")
      expect(response.body).not_to include("Set to Pending")
      expect(response.body).not_to include("update_status")
    end

    it "does not render file-level status" do
      make_request

      expect(response.body).not_to include("Status:")
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
        stub_api_request("/sections").and_return(
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: { data: [] }.to_json,
        )
        get customs_tariff_update_path(update_version)
      end

      it "displays the baseline version in explanatory text" do
        expect(response.body).to include("Comparing notes against version 1.30")
      end

      it "selects the baseline version in the compare dropdown" do
        expect(response.body).to include('<option selected="selected" value="1.30">1.30</option>')
      end

      it "does not show file-level status in compare options" do
        expect(response.body).not_to include("1.30 (pending)")
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
        stub_api_request("/sections").and_return(
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: { data: [] }.to_json,
        )
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
    let(:recognize_status_update_path) do
      Rails.application.routes.recognize_path(
        "/customs_tariff/updates/#{update_version}/update_status",
        method: :patch,
      )
    end

    it "is not routed" do
      expect { recognize_status_update_path }.to raise_error(ActionController::RoutingError)
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
