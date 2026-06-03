# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe CustomsTariff::Updates::SectionNotesController, type: :request do
  subject(:rendered_page) { make_request && response }

  before { TradeTariffAdmin::ServiceChooser.service_choice = "uk" }

  let(:update_version) { "1.31" }
  let(:section_note_id) { "127" }

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
      "section_id" => 5,
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
      get edit_customs_tariff_update_section_note_path(update_version, section_note_id)
    end

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
      stub_api_request("/customs_tariff_updates/#{update_version}/section_notes/#{section_note_id}")
        .with(query: hash_including("customs_tariff_update_version" => update_version))
        .and_return(section_note_response)
    end

    it { is_expected.to have_http_status(:ok) }
    it { is_expected.to render_template(:edit) }
  end

  describe "PATCH #update" do
    let(:make_request) do
      patch customs_tariff_update_section_note_path(update_version, section_note_id),
            params: { customs_tariff_section_note: { content: "Updated content." } }
    end

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
      stub_api_request("/customs_tariff_updates/#{update_version}/section_notes/#{section_note_id}")
        .with(query: hash_including("customs_tariff_update_version" => update_version))
        .and_return(section_note_response)
    end

    context "when the backend accepts the update" do
      before do
        stub_api_request("/customs_tariff_updates/#{update_version}/section_notes/#{section_note_id}", :patch)
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
        stub_api_request("/customs_tariff_updates/#{update_version}/section_notes/#{section_note_id}", :patch)
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

  describe "POST #preview" do
    let(:make_request) do
      post customs_tariff_section_note_preview_path, params: { content: "some markdown" }
    end

    it { is_expected.to have_http_status(:ok) }

    it "returns JSON with an html key" do
      json = JSON.parse(rendered_page.body)
      expect(json).to have_key("html")
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
