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
      "needs_review" => false,
      "approved" => false,
      "expired" => false,
      "context_hash" => "abc123",
      "created_at" => "2025-06-15T10:00:00Z",
      "updated_at" => "#{Time.zone.today.iso8601}T10:00:00Z",
      "labels" => {
        "original_description" => "Live horses",
        "description" => "Horses (live)",
        "known_brands" => %w[Brand1 Brand2],
        "colloquial_terms" => %w[Ponies],
        "synonyms" => %w[Equine Steeds],
      },
      "has_self_text" => true,
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

  before do
    TradeTariffAdmin::ServiceChooser.service_choice = "uk"
  end

  # rubocop:disable RSpec/NestedGroups
  describe "GET #index" do
    context "with HTML format" do
      let(:make_request) { get goods_nomenclature_labels_path }

      it { is_expected.to redirect_to(goods_nomenclature_self_texts_path(anchor: "labels")) }
    end

    context "with JSON format" do
      let(:make_request) { get goods_nomenclature_labels_path(format: :json) }
      let(:collection_response) do
        jsonapi_response("goods_nomenclature_label", [
          {
            "goods_nomenclature_sid" => goods_nomenclature_sid,
            "goods_nomenclature_item_id" => commodity_code,
            "score" => 0.75,
            "stale" => false,
            "manually_edited" => false,
            "original_description" => "Live horses",
          },
        ])
      end

      before do
        stub_api_request("/goods_nomenclature_labels", backend: "uk")
          .with(query: hash_including({}))
          .and_return(collection_response)
      end

      it { is_expected.to have_http_status :success }

      # rubocop:disable RSpec/MultipleExpectations
      it "returns labels data with pagination" do
        json = JSON.parse(rendered_page.body)

        expect(json["data"]).to be_an(Array)
        expect(json["data"].first["goods_nomenclature_item_id"]).to eq(commodity_code)
        expect(json["data"].first["score"]).to eq(0.75)
        expect(json["pagination"]).to include("page", "total_count", "total_pages")
      end
      # rubocop:enable RSpec/MultipleExpectations

      context "when API fails" do
        before do
          stub_api_request("/goods_nomenclature_labels", backend: "uk")
            .with(query: hash_including({}))
            .and_return(status: 500, body: { error: "Internal Server Error" }.to_json)
        end

        it { is_expected.to have_http_status :success }

        it "returns empty data" do
          json = JSON.parse(rendered_page.body)

          expect(json["data"]).to eq([])
        end
      end
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
  end

  describe "GET #show" do
    before do
      stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label", backend: "uk")
        .and_return(label_response)
      stub_api_request("/versions", backend: "uk")
        .with(query: hash_including("item_type" => "GoodsNomenclatureLabel", "item_id" => goods_nomenclature_sid.to_s))
        .and_return(versions_response)
    end

    let(:versions_response) do
      {
        status: 200,
        headers: { "content-type" => "application/json; charset=utf-8" },
        body: { data: [] }.to_json,
      }
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

    it "displays the record dates" do # rubocop:disable RSpec/MultipleExpectations
      expect(rendered_page.body).to include("Record dates")
      expect(rendered_page.body).to include("Created: 15 June 2025")
      expect(rendered_page.body).to include("Updated: Today")
    end

    it "displays the View self-text cross-link when has_self_text is true" do
      expect(rendered_page.body).to include("View self-text")
    end

    it "displays the lifecycle action buttons" do # rubocop:disable RSpec/MultipleExpectations
      expect(rendered_page.body).to include("Needs review")
      expect(rendered_page.body).to include("Generate score")
      expect(rendered_page.body).to include("Regenerate label")
    end

    context "when the label needs review" do
      let(:label_attributes) { super().merge("needs_review" => true) }

      it "displays the approve action" do
        expect(rendered_page.body).to include("Approve")
      end
    end

    context "when the label has lifecycle tags" do
      let(:label_attributes) do
        super().merge(
          "needs_review" => true,
          "manually_edited" => true,
          "stale" => true,
          "approved" => true,
          "expired" => true,
        )
      end

      it "displays all lifecycle tags" do # rubocop:disable RSpec/MultipleExpectations
        expect(rendered_page.body).to include("Needs review")
        expect(rendered_page.body).to include("Manually edited")
        expect(rendered_page.body).to include("Stale")
        expect(rendered_page.body).to include("Approved")
        expect(rendered_page.body).to include("Expired")
      end
    end

    context "when has_self_text is false" do
      let(:label_attributes) { super().merge("has_self_text" => false) }

      it "does not display the View self-text cross-link" do
        expect(rendered_page.body).not_to include("View self-text")
      end
    end

    context "when viewing a historical version via oid" do
      let(:make_request) { get goods_nomenclature_label_path(commodity_code, oid: "42") }

      let(:historical_label_response) do
        {
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: {
            data: {
              type: "goods_nomenclature_label",
              id: goods_nomenclature_sid.to_s,
              attributes: label_attributes.merge("labels" => label_attributes["labels"].merge("description" => "Old description")),
            },
            meta: { version: { current: false, oid: 42, previous_oid: 41, has_previous_version: true } },
          }.to_json,
        }
      end

      before do
        stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label", backend: "uk")
          .with(query: { "filter" => { "oid" => "42" } })
          .and_return(historical_label_response)
      end

      it { is_expected.to have_http_status :success }

      it "displays the version banner" do
        expect(rendered_page.body).to include("Historical version")
      end

      it "does not display the save button" do
        expect(rendered_page.body).not_to include("Save changes")
      end

      it "hides the action buttons" do # rubocop:disable RSpec/MultipleExpectations
        expect(rendered_page.body).not_to include("Generate score")
        expect(rendered_page.body).not_to include("Regenerate label")
      end
    end

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
  end

  describe "POST #score" do
    before do
      stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label", backend: "uk")
        .and_return(label_response)
    end

    let(:make_request) { post score_goods_nomenclature_label_path(commodity_code) }

    context "when successful" do
      before do
        stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label/score", :post, backend: "uk")
          .and_return(status: 200, body: {}.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_label_path(commodity_code)) }

      it "shows a success message" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Label score generated successfully.")
      end
    end

    context "when API fails" do
      before do
        stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label/score", :post, backend: "uk")
          .and_return(status: 500, body: { error: "Server error" }.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_label_path(commodity_code)) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to include("Failed to generate label score")
      end
    end
  end

  describe "POST #regenerate" do
    before do
      stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label", backend: "uk")
        .and_return(label_response)
    end

    let(:make_request) { post regenerate_goods_nomenclature_label_path(commodity_code) }

    context "when successful" do
      before do
        stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label/regenerate", :post, backend: "uk")
          .and_return(status: 200, body: {}.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_label_path(commodity_code)) }

      it "shows a success message" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Label regenerated successfully.")
      end
    end

    context "when API fails" do
      before do
        stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label/regenerate", :post, backend: "uk")
          .and_return(status: 500, body: { error: "Server error" }.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_label_path(commodity_code)) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Failed to regenerate label.")
      end
    end
  end

  describe "POST #approve" do
    before do
      stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label", backend: "uk")
        .and_return(label_response)
    end

    let(:make_request) { post approve_goods_nomenclature_label_path(commodity_code) }

    context "when successful" do
      before do
        stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label/approve", :post, backend: "uk")
          .and_return(status: 200, body: {}.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_label_path(commodity_code)) }

      it "shows a success message" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Label approved.")
      end
    end

    context "when API fails" do
      before do
        stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label/approve", :post, backend: "uk")
          .and_return(status: 500, body: { error: "Server error" }.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_label_path(commodity_code)) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Failed to approve label.")
      end
    end
  end

  describe "POST #reject" do
    before do
      stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label", backend: "uk")
        .and_return(label_response)
    end

    let(:make_request) { post reject_goods_nomenclature_label_path(commodity_code) }

    context "when successful" do
      before do
        stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label/reject", :post, backend: "uk")
          .and_return(status: 200, body: {}.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_label_path(commodity_code)) }

      it "shows a success message" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Label marked for review.")
      end
    end

    context "when API fails" do
      before do
        stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label/reject", :post, backend: "uk")
          .and_return(status: 500, body: { error: "Server error" }.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_label_path(commodity_code)) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Failed to reject label.")
      end
    end
  end

  describe "PATCH #update" do
    before do
      stub_api_request("/goods_nomenclatures/#{commodity_code}/goods_nomenclature_label", backend: "uk")
        .and_return(label_response)
      stub_api_request("/versions", backend: "uk")
        .with(query: hash_including("item_type" => "GoodsNomenclatureLabel", "item_id" => goods_nomenclature_sid.to_s))
        .and_return(status: 200, headers: { "content-type" => "application/json; charset=utf-8" }, body: { data: [] }.to_json)
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

      it { is_expected.to have_http_status :unprocessable_content }
      it { is_expected.to render_template(:show) }
    end
  end
  # rubocop:enable RSpec/NestedGroups

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
