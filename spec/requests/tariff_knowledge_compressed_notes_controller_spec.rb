RSpec.describe TariffKnowledgeCompressedNotesController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }

  def goods_nomenclature_sid
    12_345
  end

  def commodity_code
    "0101210000"
  end

  def compressed_note_attributes
    {
      "goods_nomenclature_sid" => goods_nomenclature_sid,
      "goods_nomenclature_item_id" => commodity_code,
      "producline_suffix" => "80",
      "goods_nomenclature_type" => "commodity",
      "content" => "Live horses are covered by chapter notes for chapter 1.",
      "metadata" => {
        "source_node_keys" => ["chapter_note:01:fragment:1"],
        "range_node_keys" => ["chapter:01"],
      },
      "context_hash" => "abc123",
      "needs_review" => true,
      "manually_edited" => false,
      "stale" => false,
      "approved" => false,
      "expired" => false,
      "generated_at" => "2025-06-15T10:00:00Z",
      "created_at" => "2025-06-15T10:00:00Z",
      "updated_at" => "#{Time.zone.today.iso8601}T10:00:00Z",
    }
  end

  def compressed_note_response
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: {
          type: "tariff_knowledge_compressed_note",
          id: goods_nomenclature_sid.to_s,
          attributes: compressed_note_attributes,
        },
      }.to_json,
    }
  end

  before do
    TradeTariffAdmin::ServiceChooser.service_choice = "uk"
  end

  describe "GET #index" do
    context "with HTML format" do
      let(:make_request) { get tariff_knowledge_compressed_notes_path }

      it { is_expected.to redirect_to(goods_nomenclature_self_texts_path(anchor: "compressed-notes")) }
    end

    context "with JSON format" do
      let(:make_request) { get tariff_knowledge_compressed_notes_path(format: :json) }

      def collection_response
        jsonapi_response("tariff_knowledge_compressed_note", [
          compressed_note_attributes.merge("content" => "Live horses are covered by chapter notes."),
        ])
      end

      def indexed_note
        {
          "goods_nomenclature_sid" => goods_nomenclature_sid,
          "goods_nomenclature_item_id" => commodity_code,
          "content" => "Live horses are covered by chapter notes.",
          "score" => nil,
        }
      end

      before do
        stub_api_request("/tariff_knowledge_compressed_notes", backend: "uk")
          .with(query: hash_including({}))
          .and_return(collection_response)
      end

      it { is_expected.to have_http_status :success }

      it "returns compressed note data" do
        expect(JSON.parse(rendered_page.body)["data"].first).to include(indexed_note)
      end

      it "returns pagination" do
        expect(JSON.parse(rendered_page.body)["pagination"]).to include("page", "total_count", "total_pages")
      end
    end
  end

  describe "GET descriptions page" do
    let(:make_request) { get goods_nomenclature_self_texts_path }

    it "shows the compressed notes tab" do
      expect(rendered_page.body).to include("Compressed notes")
    end

    it "anchors the compressed notes panel" do
      expect(rendered_page.body).to include('id="compressed-notes"')
    end

    it "renders the compressed notes table" do
      expect(rendered_page.body).to include("compressed-note-table-container")
    end

    it "loads notes from the JSON path" do
      expect(rendered_page.body).to include(tariff_knowledge_compressed_notes_path(format: :json))
    end
  end

  describe "GET #search" do
    context "with valid query" do
      let(:make_request) { get search_tariff_knowledge_compressed_notes_path(q: "horses") }

      it { is_expected.to redirect_to(goods_nomenclature_self_texts_path(anchor: "compressed-notes", q: "horses")) }
    end

    context "with blank query" do
      let(:make_request) { get search_tariff_knowledge_compressed_notes_path(q: "") }

      it { is_expected.to redirect_to(goods_nomenclature_self_texts_path(anchor: "compressed-notes")) }
    end
  end

  describe "GET #show" do
    before do
      stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/tariff_knowledge_compressed_note", backend: "uk")
        .and_return(compressed_note_response)
      stub_api_request("/versions", backend: "uk")
        .with(query: hash_including("item_type" => "TariffKnowledge::CompressedNote", "item_id" => goods_nomenclature_sid.to_s))
        .and_return(status: 200, headers: { "content-type" => "application/json; charset=utf-8" }, body: { data: [] }.to_json)
    end

    let(:make_request) { get tariff_knowledge_compressed_note_path(goods_nomenclature_sid) }

    it { is_expected.to have_http_status :success }
    it { is_expected.to render_template(:show) }

    it "displays the commodity code" do
      expect(rendered_page.body).to include(commodity_code)
    end

    it "displays the note content" do
      expect(rendered_page.body).to include("Live horses are covered by chapter notes for chapter 1.")
    end

    it "displays the source node key" do
      expect(rendered_page.body).to include("chapter_note:01:fragment:1")
    end

    it "displays the range node key" do
      expect(rendered_page.body).to include("chapter:01")
    end

    it "displays the save control" do
      expect(rendered_page.body).to include("Save changes")
    end

    it "hides score controls" do
      expect(rendered_page.body).not_to include("Generate score")
    end
  end

  describe "PATCH #update" do
    before do
      stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/tariff_knowledge_compressed_note", backend: "uk")
        .and_return(compressed_note_response)
      stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/tariff_knowledge_compressed_note", :patch, backend: "uk")
        .and_return(compressed_note_response)
    end

    let(:make_request) do
      patch tariff_knowledge_compressed_note_path(goods_nomenclature_sid),
            params: { tariff_knowledge_compressed_note: { content: "Updated evidence note" } }
    end

    it { is_expected.to redirect_to(tariff_knowledge_compressed_note_path(goods_nomenclature_sid)) }
  end

  describe "POST #regenerate" do
    before do
      stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/tariff_knowledge_compressed_note", backend: "uk")
        .and_return(compressed_note_response)
      stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/tariff_knowledge_compressed_note/regenerate", :post, backend: "uk")
        .and_return(status: 200, body: {}.to_json)
    end

    let(:make_request) { post regenerate_tariff_knowledge_compressed_note_path(goods_nomenclature_sid) }

    it { is_expected.to redirect_to(tariff_knowledge_compressed_note_path(goods_nomenclature_sid)) }
  end

  describe "POST #approve" do
    before do
      stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/tariff_knowledge_compressed_note", backend: "uk")
        .and_return(compressed_note_response)
      stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/tariff_knowledge_compressed_note/approve", :post, backend: "uk")
        .and_return(status: 200, body: {}.to_json)
    end

    let(:make_request) { post approve_tariff_knowledge_compressed_note_path(goods_nomenclature_sid) }

    it { is_expected.to redirect_to(tariff_knowledge_compressed_note_path(goods_nomenclature_sid)) }
  end

  describe "POST #reject" do
    before do
      stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/tariff_knowledge_compressed_note", backend: "uk")
        .and_return(compressed_note_response)
      stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/tariff_knowledge_compressed_note/reject", :post, backend: "uk")
        .and_return(status: 200, body: {}.to_json)
    end

    let(:make_request) { post reject_tariff_knowledge_compressed_note_path(goods_nomenclature_sid) }

    it { is_expected.to redirect_to(tariff_knowledge_compressed_note_path(goods_nomenclature_sid)) }
  end
end
