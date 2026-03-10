# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe GoodsNomenclatureSelfTextsController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }
  let(:goods_nomenclature_sid) { 12_345 }
  let(:commodity_code) { "0101210000" }
  let(:self_text_attributes) do
    {
      "goods_nomenclature_sid" => goods_nomenclature_sid,
      "goods_nomenclature_item_id" => commodity_code,
      "self_text" => "Live horses for breeding or racing purposes",
      "generation_type" => "mechanical",
      "input_context" => {
        "goods_nomenclature_class" => "commodity",
        "description" => "Horses",
        "ancestors" => [
          { "description" => "Live animals" },
          { "description" => "Live horses, asses, mules and hinnies" },
        ],
        "siblings" => ["Pure-bred breeding animals", "Other"],
      },
      "needs_review" => false,
      "manually_edited" => false,
      "stale" => false,
      "generated_at" => "2025-06-15T10:00:00Z",
      "eu_self_text" => "Horses, live, for breeding",
      "similarity_score" => 0.72,
      "coherence_score" => 0.68,
      "nomenclature_type" => "commodity",
      "score" => 0.70,
      "has_label" => true,
    }
  end
  let(:self_text_response) do
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: {
          type: "goods_nomenclature_self_text",
          id: goods_nomenclature_sid.to_s,
          attributes: self_text_attributes,
        },
      }.to_json,
    }
  end

  before do
    TradeTariffAdmin::ServiceChooser.service_choice = "uk"
  end

  # rubocop:disable RSpec/NestedGroups
  describe "GET #index" do
    context "with HTML format" do
      let(:make_request) { get goods_nomenclature_self_texts_path }

      it { is_expected.to have_http_status :success }
      it { is_expected.to render_template(:index) }

      it "displays the tabbed page heading" do
        expect(rendered_page.body).to include("Descriptions")
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "displays both tab links" do
        expect(rendered_page.body).to include("Self-texts")
        expect(rendered_page.body).to include("Labels")
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context "with JSON format" do
      let(:make_request) { get goods_nomenclature_self_texts_path(format: :json) }
      let(:collection_response) do
        jsonapi_response("goods_nomenclature_self_text", [
          {
            "goods_nomenclature_sid" => goods_nomenclature_sid,
            "goods_nomenclature_item_id" => commodity_code,
            "score" => 0.70,
            "needs_review" => false,
            "stale" => false,
            "manually_edited" => false,
            "self_text" => "Live horses for breeding",
          },
        ])
      end

      before do
        stub_api_request("/goods_nomenclature_self_texts", backend: "uk")
          .with(query: hash_including({}))
          .and_return(collection_response)
      end

      it { is_expected.to have_http_status :success }

      # rubocop:disable RSpec/MultipleExpectations
      it "returns self-texts data with pagination" do
        json = JSON.parse(rendered_page.body)

        expect(json["data"]).to be_an(Array)
        expect(json["data"].first["goods_nomenclature_item_id"]).to eq(commodity_code)
        expect(json["data"].first["score"]).to eq(0.70)
        expect(json["pagination"]).to include("page", "total_count", "total_pages")
      end
      # rubocop:enable RSpec/MultipleExpectations

      context "when API fails" do
        before do
          stub_api_request("/goods_nomenclature_self_texts", backend: "uk")
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
  # rubocop:enable RSpec/NestedGroups

  describe "GET #search" do
    context "with valid query" do
      let(:make_request) { get search_goods_nomenclature_self_texts_path(q: "horses") }

      it { is_expected.to redirect_to(goods_nomenclature_self_texts_path(q: "horses")) }
    end

    context "with blank query" do
      let(:make_request) { get search_goods_nomenclature_self_texts_path(q: "") }

      it { is_expected.to redirect_to(goods_nomenclature_self_texts_path) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Please enter a search term.")
      end
    end

    context "with query too short" do
      let(:make_request) { get search_goods_nomenclature_self_texts_path(q: "a") }

      it { is_expected.to redirect_to(goods_nomenclature_self_texts_path) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Search must be at least 2 characters.")
      end
    end

    context "with query containing extra whitespace" do
      let(:make_request) { get search_goods_nomenclature_self_texts_path(q: "  live   horses  ") }

      it { is_expected.to redirect_to(goods_nomenclature_self_texts_path(q: "live horses")) }
    end
  end

  describe "GET #show" do
    before do
      stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text", backend: "uk")
        .and_return(self_text_response)
      stub_api_request("/versions", backend: "uk")
        .with(query: hash_including("item_type" => "GoodsNomenclatureSelfText", "item_id" => goods_nomenclature_sid.to_s))
        .and_return(status: 200, headers: { "content-type" => "application/json; charset=utf-8" }, body: { data: [] }.to_json)
    end

    let(:make_request) { get goods_nomenclature_self_text_path(goods_nomenclature_sid) }

    it { is_expected.to have_http_status :success }
    it { is_expected.to render_template(:show) }

    # rubocop:disable RSpec/MultipleExpectations
    it "displays the self-text information" do
      expect(rendered_page.body).to include(commodity_code)
      expect(rendered_page.body).to include("Live horses for breeding or racing purposes")
      expect(rendered_page.body).to include("Save changes")
    end
    # rubocop:enable RSpec/MultipleExpectations

    it "displays the View labels cross-link when has_label is true" do
      expect(rendered_page.body).to include("View labels")
    end

    context "when has_label is false" do
      let(:self_text_attributes) { super().merge("has_label" => false) }

      it "does not display the View labels cross-link" do
        expect(rendered_page.body).not_to include("View labels")
      end
    end

    context "when viewing a historical version via oid" do
      let(:make_request) { get goods_nomenclature_self_text_path(goods_nomenclature_sid, oid: "42") }

      let(:historical_self_text_response) do
        {
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: {
            data: {
              type: "goods_nomenclature_self_text",
              id: goods_nomenclature_sid.to_s,
              attributes: self_text_attributes.merge("self_text" => "Old self-text content"),
            },
            meta: { version: { current: false, oid: 42, previous_oid: 41, has_previous_version: true } },
          }.to_json,
        }
      end

      before do
        stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text", backend: "uk")
          .with(query: { "filter" => { "oid" => "42" } })
          .and_return(historical_self_text_response)
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
        expect(rendered_page.body).not_to include("Regenerate self-text")
      end
    end

    context "when self-text not found" do
      before do
        stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text", backend: "uk")
          .and_return(status: 404, body: { error: "Not found" }.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_self_texts_path) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to include("Self-text not found")
      end
    end
  end

  describe "POST #score" do
    before do
      stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text", backend: "uk")
        .and_return(self_text_response)
    end

    let(:make_request) { post score_goods_nomenclature_self_text_path(goods_nomenclature_sid) }

    context "when successful" do
      before do
        stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text/score", :post, backend: "uk")
          .and_return(status: 200, body: {}.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_self_text_path(goods_nomenclature_sid)) }

      it "shows a success message" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Score generated successfully.")
      end
    end

    context "when API fails" do
      before do
        stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text/score", :post, backend: "uk")
          .and_return(status: 500, body: { error: "Server error" }.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_self_text_path(goods_nomenclature_sid)) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to include("Failed to generate score")
      end
    end
  end

  describe "POST #regenerate" do
    before do
      stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text", backend: "uk")
        .and_return(self_text_response)
    end

    let(:make_request) { post regenerate_goods_nomenclature_self_text_path(goods_nomenclature_sid) }

    context "when successful" do
      before do
        stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text/regenerate", :post, backend: "uk")
          .and_return(status: 200, body: {}.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_self_text_path(goods_nomenclature_sid)) }

      it "shows a success message" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Self-text regenerated successfully.")
      end
    end

    context "when API fails" do
      before do
        stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text/regenerate", :post, backend: "uk")
          .and_return(status: 500, body: { error: "Server error" }.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_self_text_path(goods_nomenclature_sid)) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Failed to regenerate self-text.")
      end
    end
  end

  describe "POST #approve" do
    before do
      stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text", backend: "uk")
        .and_return(self_text_response)
    end

    let(:make_request) { post approve_goods_nomenclature_self_text_path(goods_nomenclature_sid) }

    context "when successful" do
      before do
        stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text/approve", :post, backend: "uk")
          .and_return(status: 200, body: {}.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_self_text_path(goods_nomenclature_sid)) }

      it "shows a success message" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Self-text approved.")
      end
    end

    context "when API fails" do
      before do
        stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text/approve", :post, backend: "uk")
          .and_return(status: 500, body: { error: "Server error" }.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_self_text_path(goods_nomenclature_sid)) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Failed to approve self-text.")
      end
    end
  end

  describe "POST #reject" do
    before do
      stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text", backend: "uk")
        .and_return(self_text_response)
    end

    let(:make_request) { post reject_goods_nomenclature_self_text_path(goods_nomenclature_sid) }

    context "when successful" do
      before do
        stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text/reject", :post, backend: "uk")
          .and_return(status: 200, body: {}.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_self_text_path(goods_nomenclature_sid)) }

      it "shows a success message" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Self-text marked for review.")
      end
    end

    context "when API fails" do
      before do
        stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text/reject", :post, backend: "uk")
          .and_return(status: 500, body: { error: "Server error" }.to_json)
      end

      it { is_expected.to redirect_to(goods_nomenclature_self_text_path(goods_nomenclature_sid)) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Failed to reject self-text.")
      end
    end
  end

  describe "PATCH #update" do
    before do
      stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text", backend: "uk")
        .and_return(self_text_response)
      stub_api_request("/versions", backend: "uk")
        .with(query: hash_including("item_type" => "GoodsNomenclatureSelfText", "item_id" => goods_nomenclature_sid.to_s))
        .and_return(status: 200, headers: { "content-type" => "application/json; charset=utf-8" }, body: { data: [] }.to_json)
    end

    let(:make_request) do
      patch goods_nomenclature_self_text_path(goods_nomenclature_sid),
            params: {
              goods_nomenclature_self_text: {
                self_text: "Updated self-text content",
              },
            }
    end

    context "with valid update" do
      before do
        stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text", :patch, backend: "uk")
          .and_return(self_text_response)
      end

      it { is_expected.to redirect_to(goods_nomenclature_self_text_path(goods_nomenclature_sid)) }

      it "shows a success message" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Self-text updated successfully.")
      end
    end

    context "with invalid update" do
      before do
        stub_api_request("/goods_nomenclatures/#{goods_nomenclature_sid}/goods_nomenclature_self_text", :patch, backend: "uk")
          .and_return(webmock_response(:error, self_text: "can't be blank"))
      end

      it { is_expected.to have_http_status :unprocessable_entity }
      it { is_expected.to render_template(:show) }
    end
  end

  context "when user is HMRC admin (unauthorized)" do
    let(:current_user) { create(:user, :hmrc_admin) }
    let(:make_request) { get goods_nomenclature_self_texts_path }

    it { is_expected.to have_http_status :forbidden }
    it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
  end

  context "when user is auditor (unauthorized)" do
    let(:current_user) { create(:user, :auditor) }
    let(:make_request) { get goods_nomenclature_self_texts_path }

    it { is_expected.to have_http_status :forbidden }
    it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
  end

  context "when user is guest (unauthorized)" do
    let(:current_user) { create(:user, :guest) }
    let(:make_request) { get goods_nomenclature_self_texts_path }

    it { is_expected.to have_http_status :forbidden }
    it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
