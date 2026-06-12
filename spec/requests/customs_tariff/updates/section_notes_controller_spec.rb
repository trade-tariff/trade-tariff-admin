# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe CustomsTariff::Updates::SectionNotesController, type: :request do
  subject(:rendered_page) { make_request && response }

  before { TradeTariffAdmin::ServiceChooser.service_choice = "uk" }

  let(:update_version) { "1.31" }
  let(:section_note_id) { "127" }
  let(:section_id) { "5" }

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

  let(:section_note_attributes) do
    {
      "id" => section_note_id,
      "section_id" => section_id.to_i,
      "content" => '## Section 5\n\nOriginal content.',
      "customs_tariff_update_version" => update_version,
      "file_diff" => nil,
      "versions" => [],
    }
  end

  let(:section_note_response) do
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: {
          type: "customs_tariff_section_note",
          id: section_note_id,
          attributes: section_note_attributes,
        },
      }.to_json,
    }
  end

  describe "GET #edit" do
    let(:make_request) do
      get edit_customs_tariff_update_section_note_path(update_version, section_id)
    end

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
      stub_api_request("/customs_tariff_updates/#{update_version}/section_notes/#{section_id}")
        .with(query: hash_including("customs_tariff_update_version" => update_version))
        .and_return(section_note_response)
    end

    it { is_expected.to have_http_status(:ok) }
    it { is_expected.to render_template(:edit) }
  end

  describe "PATCH #update" do
    let(:make_request) do
      patch customs_tariff_update_section_note_path(update_version, section_id),
            params: { customs_tariff_section_note: { content: "Updated content." } }
    end

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
      stub_api_request("/customs_tariff_updates/#{update_version}/section_notes/#{section_id}")
        .with(query: hash_including("customs_tariff_update_version" => update_version))
        .and_return(section_note_response)
    end

    context "when the backend accepts the update" do
      before do
        stub_api_request("/customs_tariff_updates/#{update_version}/section_notes/#{section_id}", :patch)
          .and_return(
            status: 200,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: {
              data: {
                type: "customs_tariff_section_note",
                id: section_note_id,
                attributes: section_note_attributes.merge("content" => "Updated content."),
              },
            }.to_json,
          )
      end

      it { is_expected.to redirect_to(customs_tariff_update_path(update_version)) }

      it "sets a success flash notice" do
        make_request
        expect(session.dig("flash", "flashes", "notice")).to eq("Section note updated.")
      end
    end

    context "when the backend rejects the update with a 422" do
      before do
        stub_api_request("/customs_tariff_updates/#{update_version}/section_notes/#{section_id}", :patch)
          .and_return(
            status: 422,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: {
              errors: [
                { source: { pointer: "/data/attributes/content" }, detail: "is invalid" },
              ],
            }.to_json,
          )
      end

      it { is_expected.to render_template(:edit) }
    end
  end

  describe "DELETE #destroy" do
    let(:make_request) do
      delete customs_tariff_update_section_note_path(update_version, section_id)
    end

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
      stub_api_request("/customs_tariff_updates/#{update_version}/section_notes/#{section_id}")
        .with(query: hash_including("customs_tariff_update_version" => update_version))
        .and_return(section_note_response)
    end

    context "when the backend accepts the delete" do
      before do
        stub_api_request("/customs_tariff_updates/#{update_version}/section_notes/#{section_id}", :delete)
          .and_return(status: 204, body: "", headers: {})
      end

      it { is_expected.to redirect_to(customs_tariff_update_path(update_version)) }

      it "sets a success flash notice" do
        make_request
        expect(session.dig("flash", "flashes", "notice")).to eq("Section note removed.")
      end
    end
  end

  describe "POST #preview" do
    let(:make_request) do
      post customs_tariff_section_note_preview_path, params: { content: "some markdown" }
    end

    it { is_expected.to have_http_status(:ok) }

    it "returns JSON with an html key" do
      json = JSON.parse(rendered_page.body)
      expect(json).to have_key("html")
    end

    context "when the content references a chapter code" do
      let(:make_request) do
        post customs_tariff_section_note_preview_path, params: { content: "goods of Chapter 71" }
      end

      it "linkifies the code reference" do
        json = JSON.parse(rendered_page.body)
        expect(json["html"]).to include("search?q=71")
      end
    end
  end

  describe "GET #new" do
    let(:make_request) do
      get new_customs_tariff_update_section_note_path(update_version),
          params: { section_id: }
    end

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
    end

    it { is_expected.to have_http_status(:ok) }
    it { is_expected.to render_template(:new) }
  end

  describe "POST #create" do
    let(:make_request) do
      post customs_tariff_update_section_notes_path(update_version),
           params: {
             customs_tariff_section_note: { content: "Manually added content." },
             section_id:,
           }
    end

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
    end

    context "when the backend accepts the create" do
      before do
        stub_api_request("/customs_tariff_updates/#{update_version}/section_notes", :post)
          .and_return(
            status: 201,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: {
              data: {
                type: "customs_tariff_section_note",
                id: "200",
                attributes: section_note_attributes.merge(
                  "section_id" => 5,
                  "content" => "Manually added content.",
                ),
              },
            }.to_json,
          )
      end

      it { is_expected.to redirect_to(customs_tariff_update_path(update_version)) }

      it "sets a success flash notice" do
        make_request
        expect(session.dig("flash", "flashes", "notice")).to eq("Section note added.")
      end
    end

    context "when the backend rejects the create with a 422" do
      before do
        stub_api_request("/customs_tariff_updates/#{update_version}/section_notes", :post)
          .and_return(
            status: 422,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: { errors: [{ detail: "Content can't be blank" }] }.to_json,
          )
      end

      it { is_expected.to have_http_status(:unprocessable_content) }
      it { is_expected.to render_template(:new) }
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
