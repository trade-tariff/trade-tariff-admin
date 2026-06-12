# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe CustomsTariff::Updates::ChapterNotesController, type: :request do
  subject(:rendered_page) { make_request && response }

  before { TradeTariffAdmin::ServiceChooser.service_choice = "uk" }

  let(:update_version) { "1.31" }
  let(:section_id)     { "3" }

  let(:update_response) do
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: {
          type: "customs_tariff_update",
          id: update_version,
          attributes: {
            "version" => update_version,
            "status" => "pending",
            "validity_start_date" => "2026-01-01",
            "validity_end_date" => nil,
            "source_url" => "https://example.com/doc.pdf",
            "document_created_on" => "2026-01-01",
            "created_at" => "2026-01-01T00:00:00Z",
            "updated_at" => "2026-01-01T00:00:00Z",
          },
        },
      }.to_json,
    }
  end

  let(:chapter_notes_response) do
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: [
          {
            type: "customs_tariff_chapter_note",
            id: "101",
            attributes: {
              "chapter_id" => "15",
              "content" => "## Chapter 15\n\nSome content.",
              "customs_tariff_update_version" => update_version,
              "file_diff" => nil,
              "versions" => [],
            },
          },
        ],
      }.to_json,
    }
  end

  let(:chapter_note_id) { "101" }
  let(:chapter_note_path_id) { chapter_note_attributes["chapter_id"] }

  let(:chapter_note_attributes) do
    {
      "chapter_id" => "15",
      "content" => "## Chapter 15\n\nSome content.",
      "customs_tariff_update_version" => update_version,
      "file_diff" => nil,
      "versions" => [],
    }
  end

  let(:chapter_note_response) do
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: {
          type: "customs_tariff_chapter_note",
          id: chapter_note_id,
          attributes: chapter_note_attributes,
        },
      }.to_json,
    }
  end

  describe "GET #index" do
    let(:make_request) do
      get customs_tariff_update_section_chapter_notes_path(update_version, section_id)
    end

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
      stub_api_request("/sections/#{section_id}")
        .and_return(
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: {
            data: {
              type: "section",
              id: section_id,
              attributes: { "title" => "Section #{section_id}", "position" => section_id.to_i },
              relationships: { chapters: { data: [] } },
            },
          }.to_json,
        )
      stub_api_request("/customs_tariff_updates/#{update_version}/chapter_notes")
        .with(query: hash_including("section_id" => section_id))
        .and_return(chapter_notes_response)
    end

    it { is_expected.to have_http_status(:ok) }
    it { is_expected.to render_template(:index) }

    context "when compare_version is present and a note has changed" do
      let(:compare_version) { "1.30" }

      let(:changed_notes_response) do
        {
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: {
            data: [
              {
                type: "customs_tariff_chapter_note",
                id: "101",
                attributes: {
                  "chapter_id" => "15",
                  "content" => "## Chapter 15\n\nUpdated content.",
                  "customs_tariff_update_version" => update_version,
                  "file_diff" => {
                    "changed_fields" => %w[content],
                    "changes" => { "content" => { "type" => "text", "diff" => [] } },
                  },
                  "versions" => [],
                },
              },
            ],
          }.to_json,
        }
      end

      let(:make_request) do
        get customs_tariff_update_section_chapter_notes_path(update_version, section_id),
            params: { compare_version: }
      end

      before do
        stub_api_request("/customs_tariff_updates/#{update_version}")
          .and_return(update_response)
        stub_api_request("/sections/#{section_id}")
          .and_return(
            status: 200,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: {
              data: {
                type: "section",
                id: section_id,
                attributes: { "title" => "Section #{section_id}", "position" => section_id.to_i },
                relationships: { chapters: { data: [] } },
              },
            }.to_json,
          )
        stub_api_request("/customs_tariff_updates/#{update_version}/chapter_notes")
          .with(query: hash_including("section_id" => section_id, "compare_version" => compare_version))
          .and_return(changed_notes_response)
      end

      it "renders a View diff link for the changed note", :aggregate_failures do
        make_request
        expect(response.body).to include("View diff")
        expect(response.body).to include(
          customs_tariff_update_comparison_chapter_note_path(update_version, "15"),
        )
      end

      it "does not render the inline changeset detail row" do
        make_request
        expect(response.body).not_to include("diff-field")
      end
    end

    context "when a section has a chapter with no corresponding note" do
      let(:absent_chapter_id) { "03" }

      let(:section_with_chapter_response) do
        {
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: {
            data: {
              type: "section",
              id: section_id,
              attributes: { "title" => "Section #{section_id}", "position" => section_id.to_i },
              relationships: {
                chapters: { data: [{ "type" => "chapter", "id" => "#{absent_chapter_id}00000000" }] },
              },
            },
            included: [
              {
                type: "chapter",
                id: "#{absent_chapter_id}00000000",
                attributes: {
                  "goods_nomenclature_item_id" => "#{absent_chapter_id}00000000",
                  "headings_from" => "#{absent_chapter_id}01",
                  "headings_to" => "#{absent_chapter_id}99",
                  "description" => "Chapter #{absent_chapter_id}",
                },
              },
            ],
          }.to_json,
        }
      end

      before do
        stub_api_request("/customs_tariff_updates/#{update_version}").and_return(update_response)
        stub_api_request("/sections/#{section_id}").and_return(section_with_chapter_response)
        stub_api_request("/customs_tariff_updates/#{update_version}/chapter_notes")
          .with(query: hash_including("section_id" => section_id))
          .and_return(
            status: 200,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: { data: [] }.to_json,
          )
        get customs_tariff_update_section_chapter_notes_path(update_version, section_id)
      end

      it "includes the Add link URL for the absent chapter" do
        expected_path = CGI.escapeHTML(new_customs_tariff_update_chapter_note_path(update_version, chapter_id: absent_chapter_id, section_id:))
        expect(response.body).to include(expected_path)
      end

      it "renders the Add link text for the absent chapter" do
        expect(response.body).to match(/>\s*Add\s*</)
      end
    end
  end

  describe "GET #new" do
    let(:chapter_id) { "03" }

    let(:make_request) do
      get new_customs_tariff_update_chapter_note_path(update_version),
          params: { chapter_id:, section_id: }
    end

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
    end

    it { is_expected.to have_http_status(:ok) }
    it { is_expected.to render_template(:new) }
  end

  describe "POST #create" do
    let(:chapter_id) { "03" }

    let(:make_request) do
      post customs_tariff_update_chapter_notes_path(update_version),
           params: {
             customs_tariff_chapter_note: { content: "New chapter note content." },
             chapter_id:,
             section_id:,
           }
    end

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
    end

    context "when the backend accepts the create" do
      before do
        stub_api_request("/customs_tariff_updates/#{update_version}/chapter_notes", :post)
          .and_return(
            status: 201,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: {
              data: {
                type: "customs_tariff_chapter_note",
                id: "201",
                attributes: {
                  "chapter_id" => chapter_id,
                  "content" => "New chapter note content.",
                  "customs_tariff_update_version" => update_version,
                  "file_diff" => nil,
                  "versions" => [],
                },
              },
            }.to_json,
          )
      end

      it { is_expected.to redirect_to(customs_tariff_update_section_chapter_notes_path(update_version, section_id)) }

      it "sets a success flash notice" do
        make_request
        expect(session.dig("flash", "flashes", "notice")).to eq("Chapter note added.")
      end
    end

    context "when the backend rejects the create with a 422" do
      before do
        stub_api_request("/customs_tariff_updates/#{update_version}/chapter_notes", :post)
          .and_return(
            status: 422,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: { errors: [{ detail: "Chapter can't be blank" }] }.to_json,
          )
      end

      it { is_expected.to have_http_status(:unprocessable_content) }
      it { is_expected.to render_template(:new) }
    end
  end

  describe "GET #edit" do
    let(:make_request) do
      get edit_customs_tariff_update_chapter_note_path(update_version, chapter_note_path_id),
          params: { section_id: }
    end

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
      stub_api_request("/customs_tariff_updates/#{update_version}/chapter_notes/#{chapter_note_path_id}")
        .with(query: hash_including("customs_tariff_update_version" => update_version))
        .and_return(chapter_note_response)
    end

    it { is_expected.to have_http_status(:ok) }
    it { is_expected.to render_template(:edit) }
  end

  describe "PATCH #update" do
    let(:make_request) do
      patch customs_tariff_update_chapter_note_path(update_version, chapter_note_path_id),
            params: {
              customs_tariff_chapter_note: { content: "Updated content." },
              section_id:,
            }
    end

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
      stub_api_request("/customs_tariff_updates/#{update_version}/chapter_notes/#{chapter_note_path_id}")
        .with(query: hash_including("customs_tariff_update_version" => update_version))
        .and_return(chapter_note_response)
    end

    context "when the backend accepts the update" do
      before do
        stub_api_request("/customs_tariff_updates/#{update_version}/chapter_notes/#{chapter_note_path_id}", :patch)
          .and_return(
            status: 200,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: {
              data: {
                type: "customs_tariff_chapter_note",
                id: chapter_note_id,
                attributes: chapter_note_attributes.merge("content" => "Updated content."),
              },
            }.to_json,
          )
      end

      it { is_expected.to redirect_to(customs_tariff_update_section_chapter_notes_path(update_version, section_id)) }

      it "sets a success flash notice" do
        make_request
        expect(session.dig("flash", "flashes", "notice")).to eq("Chapter note updated.")
      end
    end

    context "when the backend rejects the update with a 422" do
      before do
        stub_api_request("/customs_tariff_updates/#{update_version}/chapter_notes/#{chapter_note_path_id}", :patch)
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
      post customs_tariff_chapter_note_preview_path, params: { content: "some markdown" }
    end

    it { is_expected.to have_http_status(:ok) }

    it "returns JSON with an html key" do
      json = JSON.parse(rendered_page.body)
      expect(json).to have_key("html")
    end

    context "when the content references a chapter code" do
      let(:make_request) do
        post customs_tariff_chapter_note_preview_path, params: { content: "goods of Chapter 71" }
      end

      it "linkifies the code reference" do
        json = JSON.parse(rendered_page.body)
        expect(json["html"]).to include("search?q=71")
      end
    end
  end

  describe "DELETE #destroy" do
    let(:make_request) do
      delete customs_tariff_update_chapter_note_path(update_version, chapter_note_path_id),
             params: { section_id: }
    end

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
      stub_api_request("/customs_tariff_updates/#{update_version}/chapter_notes/#{chapter_note_path_id}")
        .with(query: hash_including("customs_tariff_update_version" => update_version))
        .and_return(chapter_note_response)
    end

    context "when the backend accepts the delete" do
      before do
        stub_api_request("/customs_tariff_updates/#{update_version}/chapter_notes/#{chapter_note_path_id}", :delete)
          .and_return(status: 204, body: "", headers: {})
      end

      it { is_expected.to redirect_to(customs_tariff_update_section_chapter_notes_path(update_version, section_id)) }

      it "sets a success flash notice" do
        make_request
        expect(session.dig("flash", "flashes", "notice")).to eq("Chapter note removed.")
      end
    end

    context "when the backend returns 404" do
      before do
        stub_api_request("/customs_tariff_updates/#{update_version}/chapter_notes/#{chapter_note_path_id}", :delete)
          .and_return(status: 404, body: "", headers: {})
      end

      it { is_expected.to redirect_to(customs_tariff_update_section_chapter_notes_path(update_version, section_id)) }

      it "sets an alert flash" do
        make_request
        expect(session.dig("flash", "flashes", "alert")).to eq("Chapter note could not be found.")
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
