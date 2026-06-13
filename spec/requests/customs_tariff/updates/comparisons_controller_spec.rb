# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe CustomsTariff::Updates::ComparisonsController, type: :request do
  subject(:rendered_page) { make_request && response }

  before { TradeTariffAdmin::ServiceChooser.service_choice = "uk" }

  let(:update_version)  { "1.32" }
  let(:compare_version) { "1.31" }
  let(:section_note_id) { "42" }
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
      "content" => "## Section 5\n\nSome content here.",
      "customs_tariff_update_version" => update_version,
      "file_diff" => { "changed_fields" => %w[content], "changes" => {} },
      "versions" => [],
    }
  end

  let(:section_notes_response) do
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: [
          {
            type: "customs_tariff_section_note",
            id: section_note_id,
            attributes: section_note_attributes,
          },
        ],
      }.to_json,
    }
  end

  describe "GET #show" do
    let(:make_request) do
      get customs_tariff_update_comparison_section_note_path(update_version, section_id),
          params: { compare_version: }
    end

    let(:single_note_response) do
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

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
      stub_api_request("/customs_tariff_updates/#{update_version}/section_notes/#{section_id}")
        .with(query: hash_including(
          "customs_tariff_update_version" => update_version,
          "compare_version" => compare_version,
        ))
        .and_return(single_note_response)
    end

    it { is_expected.to have_http_status(:ok) }
    it { is_expected.to render_template(:show) }

    context "when compare_version param is missing" do
      let(:make_request) do
        get customs_tariff_update_comparison_section_note_path(update_version, section_id)
      end

      it { is_expected.to redirect_to(customs_tariff_update_path(update_version)) }
    end
  end

  describe "GET #show_chapter_note" do
    let(:chapter_note_id) { "2164" }

    let(:chapter_note_attributes) do
      {
        "chapter_id" => "41",
        "content" => "## Chapter 41\n\nSome content.",
        "customs_tariff_update_version" => update_version,
        "file_diff" => { "changed_fields" => %w[content], "changes" => {} },
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

    let(:make_request) do
      get customs_tariff_update_comparison_chapter_note_path(update_version, chapter_note_id),
          params: { compare_version:, section_id: "8" }
    end

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
      stub_api_request("/customs_tariff_updates/#{update_version}/chapter_notes/#{chapter_note_id}")
        .with(query: hash_including(
          "customs_tariff_update_version" => update_version,
          "compare_version" => compare_version,
        ))
        .and_return(chapter_note_response)
    end

    it { is_expected.to have_http_status(:ok) }
    it { is_expected.to render_template(:show_chapter_note) }

    context "when compare_version param is missing" do
      let(:make_request) do
        get customs_tariff_update_comparison_chapter_note_path(update_version, chapter_note_id),
            params: { section_id: "8" }
      end

      it { is_expected.to redirect_to(customs_tariff_update_path(update_version)) }
    end
  end

  describe "GET #index" do
    let(:make_request) do
      get customs_tariff_update_comparison_path(update_version),
          params: { compare_version: }
    end

    before do
      stub_api_request("/customs_tariff_updates/#{update_version}")
        .and_return(update_response)
      stub_api_request("/customs_tariff_updates/#{update_version}/section_notes")
        .with(query: hash_including("compare_version" => compare_version))
        .and_return(section_notes_response)
    end

    it { is_expected.to have_http_status(:ok) }
    it { is_expected.to render_template(:index) }

    context "when compare_version param is missing" do
      let(:make_request) do
        get customs_tariff_update_comparison_path(update_version)
      end

      it { is_expected.to redirect_to(customs_tariff_update_path(update_version)) }

      it "sets an alert flash" do
        make_request
        expect(session.dig("flash", "flashes", "alert")).to eq("Please select a version to compare against.")
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
