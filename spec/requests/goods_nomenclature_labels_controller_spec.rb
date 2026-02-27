# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe GoodsNomenclatureLabelsController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }
  let(:label_attributes) do
    {
      "goods_nomenclature_sid" => goods_nomenclature_sid,
      "goods_nomenclature_item_id" => commodity_code,
      "goods_nomenclature_type" => "commodity",
      "producline_suffix" => "80",
      "stale" => false,
      "manually_edited" => false,
      "context_hash" => "abc123",
      "labels" => {
        "original_description" => "Live horses",
        "description" => "Horses (live)",
        "known_brands" => %w[Brand1 Brand2],
        "colloquial_terms" => %w[Ponies],
        "synonyms" => %w[Equine Steeds],
      },
    }
  end
  let(:label_response) do
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: {
          type: "goods_nomenclature_label",
          id: goods_nomenclature_sid.to_s,
          attributes: label_attributes,
        },
      }.to_json,
    }
  end
  let(:commodity_code) { "0101210000" }
  let(:goods_nomenclature_sid) { 12_345 }
  let(:stats_response) do
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: {
          type: "goods_nomenclature_label_stats",
          id: "stats",
          attributes: {
            total_goods_nomenclatures: 10_000,
            descriptions_count: 9_500,
            known_brands_count: 2_000,
            colloquial_terms_count: 1_500,
            synonyms_count: 3_000,
            ai_created_only: 8_000,
            human_edited: 2_000,
            coverage_by_chapter: [
              { chapter: "01", count: 100 },
              { chapter: "02", count: 50 },
            ],
          },
        },
      }.to_json,
    }
  end

  before do
    TradeTariffAdmin::ServiceChooser.service_choice = "uk"
    stub_api_request("/goods_nomenclature_labels/stats", backend: "uk")
      .and_return(stats_response)
  end

  describe "GET #index" do
    let(:make_request) { get goods_nomenclature_labels_path }

    it { is_expected.to have_http_status :success }
    it { is_expected.to render_template(:index) }

    it "displays the search form" do
      expect(rendered_page.body).to include("Search for Label")
    end

    it "displays the about labels guidance" do
      expect(rendered_page.body).to include("About labels")
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "displays label statistics by kind" do
      expect(rendered_page.body).to include("Label Statistics")
      expect(rendered_page.body).to include("Goods nomenclatures with labels")
      expect(rendered_page.body).to include("By Kind")
      expect(rendered_page.body).to include("Known brands")
      expect(rendered_page.body).to include("Synonyms")
    end

    it "displays origin statistics" do
      expect(rendered_page.body).to include("By Origin")
      expect(rendered_page.body).to include("AI-created only")
      expect(rendered_page.body).to include("8,000")
      expect(rendered_page.body).to include("Human-edited")
      expect(rendered_page.body).to include("2,000")
    end

    it "displays the coverage chart" do
      expect(rendered_page.body).to include("Coverage by Chapter")
      expect(rendered_page.body).to include("label-coverage-chart")
    end
    # rubocop:enable RSpec/MultipleExpectations

    context "when stats API fails" do
      before do
        stub_api_request("/goods_nomenclature_labels/stats", backend: "uk")
          .and_return(status: 500, body: { error: "Internal Server Error" }.to_json)
      end

      it { is_expected.to have_http_status :success }

      it "does not display statistics" do
        expect(rendered_page.body).not_to include("Label Statistics")
      end

      it "still displays the search form" do
        expect(rendered_page.body).to include("Search for Label")
      end
    end

    context "when on XI service" do
      before { TradeTariffAdmin::ServiceChooser.service_choice = "xi" }

      it { is_expected.to render_template("errors/not_found") }
    end
  end

  describe "GET #search" do
    context "with valid commodity code" do
      let(:make_request) { get search_goods_nomenclature_labels_path(commodity_code: commodity_code) }

      it { is_expected.to redirect_to(goods_nomenclature_label_path(commodity_code)) }
    end

    context "with commodity code with spaces" do
      let(:make_request) { get search_goods_nomenclature_labels_path(commodity_code: "0101 2100 00") }

      it { is_expected.to redirect_to(goods_nomenclature_label_path(commodity_code)) }
    end

    context "with invalid commodity code (not 10 digits)" do
      let(:make_request) { get search_goods_nomenclature_labels_path(commodity_code: "12345") }

      it { is_expected.to redirect_to(goods_nomenclature_labels_path) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Commodity code must be 10 digits.")
      end
    end

    context "with blank commodity code" do
      let(:make_request) { get search_goods_nomenclature_labels_path(commodity_code: "") }

      it { is_expected.to redirect_to(goods_nomenclature_labels_path) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Please enter a commodity code.")
      end
    end

    context "when on XI service" do
      before { TradeTariffAdmin::ServiceChooser.service_choice = "xi" }

      let(:make_request) { get search_goods_nomenclature_labels_path(commodity_code: commodity_code) }

      it { is_expected.to render_template("errors/not_found") }
    end
  end

  describe "GET #show" do
    before do
      stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label", backend: "uk")
        .and_return(label_response)
    end

    let(:make_request) { get goods_nomenclature_label_path(commodity_code) }

    it { is_expected.to have_http_status :success }
    it { is_expected.to render_template(:show) }

    # rubocop:disable RSpec/MultipleExpectations
    it "displays the label information in an editable form" do
      expect(rendered_page.body).to include(commodity_code)
      expect(rendered_page.body).to include("Horses (live)")
      expect(rendered_page.body).to include("Save changes")
    end
    # rubocop:enable RSpec/MultipleExpectations

    context "when label not found" do
      before do
        stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label", backend: "uk")
          .and_return(status: 404, body: { error: "Not found" }.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_labels_path) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to include("Label not found")
      end
    end

    context "when on XI service" do
      before { TradeTariffAdmin::ServiceChooser.service_choice = "xi" }

      it { is_expected.to render_template("errors/not_found") }
    end
  end

  describe "PATCH #update" do
    before do
      stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label", backend: "uk")
        .and_return(label_response)
    end

    let(:make_request) do
      patch goods_nomenclature_label_path(commodity_code),
            params: {
              goods_nomenclature_label: {
                description: "Updated description",
                known_brands_text: "NewBrand1\nNewBrand2",
                colloquial_terms_text: "NewTerm",
                synonyms_text: "Synonym1\nSynonym2",
              },
            }
    end

    context "with valid update" do
      before do
        stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label", :patch, backend: "uk")
          .and_return(label_response)
      end

      it { is_expected.to redirect_to(goods_nomenclature_label_path(commodity_code)) }

      it "shows a success message" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Label updated successfully.")
      end
    end

    context "with invalid update" do
      before do
        stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label", :patch, backend: "uk")
          .and_return(webmock_response(:error, description: "can't be blank"))
      end

      it { is_expected.to have_http_status :unprocessable_entity }
      it { is_expected.to render_template(:show) }
    end

    context "when on XI service" do
      before { TradeTariffAdmin::ServiceChooser.service_choice = "xi" }

      it { is_expected.to render_template("errors/not_found") }
    end
  end

  context "when user is HMRC admin (unauthorized)" do
    let(:current_user) { create(:user, :hmrc_admin) }
    let(:make_request) { get goods_nomenclature_labels_path }

    it { is_expected.to have_http_status :forbidden }
    it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
  end

  context "when user is auditor (unauthorized)" do
    let(:current_user) { create(:user, :auditor) }
    let(:make_request) { get goods_nomenclature_labels_path }

    it { is_expected.to have_http_status :forbidden }
    it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
  end

  context "when user is guest (unauthorized)" do
    let(:current_user) { create(:user, :guest) }
    let(:make_request) { get goods_nomenclature_labels_path }

    it { is_expected.to have_http_status :forbidden }
    it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
