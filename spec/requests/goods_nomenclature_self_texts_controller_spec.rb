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
      "approved" => false,
      "expired" => false,
      "created_at" => "2025-06-15T10:00:00Z",
      "updated_at" => "#{Time.zone.today.iso8601}T10:00:00Z",
      "eu_self_text" => "Horses, live, for breeding",
      "similarity_score" => 0.72,
      "coherence_score" => 0.68,
      "nomenclature_type" => "commodity",
      "score" => 0.70,
      "has_label" => true,
    }
  end

  def self_text_response
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

  describe "GET #index" do
    def collection_response
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

    def index_json
      JSON.parse(rendered_page.body)
    end

    context "with HTML format" do
      let(:make_request) { get goods_nomenclature_self_texts_path }

      def generated_content_table_controller
        Rails.root.join("app/javascript/controllers/generated_content_table_controller.js").read
      end

      def generated_content_tabs_controller
        Rails.root.join("app/javascript/controllers/generated_content_tabs_controller.js").read
      end

      it { is_expected.to have_http_status :success }
      it { is_expected.to render_template(:index) }

      it "displays the tabbed page heading" do
        expect(rendered_page.body).to include("Descriptions")
      end

      it "shows the self-texts tab" do
        expect(rendered_page.body).to include("Self-texts")
      end

      it "shows the labels tab" do
        expect(rendered_page.body).to include("Labels")
      end

      it "shows the commodity type filter" do
        expect(rendered_page.body).to include('for="st-type-commodity"')
      end

      it "shows the subheading type filter" do
        expect(rendered_page.body).to include('for="st-type-subheading"')
      end

      it "shows the all types filter" do
        expect(rendered_page.body).to include('for="st-type-all"')
      end

      it "does not show a heading type filter" do
        expect(rendered_page.body).not_to include('for="st-type-heading"')
      end

      it "renders the self-text table inside a bounded container" do
        expect(rendered_page.body).to include('class="self-text-table-container" data-generated-content-table-target="table"')
      end

      it "renders the labels table inside a bounded container" do
        expect(rendered_page.body).to include('class="label-table-container" data-generated-content-table-target="table"')
      end

      it "labels the state filters as tags" do
        expect(rendered_page.body).to include('<legend class="govuk-fieldset__legend govuk-fieldset__legend--s">Tags</legend>')
      end

      it "shows the approved self-text tag filter" do
        expect(rendered_page.body).to include('id="st-tags-approved"')
      end

      it "updates tags when the filter changes" do
        expect(rendered_page.body).to include('data-action="change->generated-content-table#changeTags"')
      end

      it "filters by the approved status" do
        expect(rendered_page.body).to include('data-status="approved"')
      end

      it "shows the approved label tag filter" do
        expect(rendered_page.body).to include('id="lb-tags-approved"')
      end

      it "shows the needs review label tag filter" do
        expect(rendered_page.body).to include('id="lb-tags-needs_review"')
      end

      it "shows the expired label tag filter" do
        expect(rendered_page.body).to include('id="lb-tags-expired"')
      end

      it "labels a low self-text score as Low" do
        expect(rendered_page.body).to include('for="st-score-bad">Low</label>')
      end

      it "labels a very high self-text score as Very High" do
        expect(rendered_page.body).to include('for="st-score-amazing">Very High</label>')
      end

      it "labels a low label score as Low" do
        expect(rendered_page.body).to include('for="lb-score-bad">Low</label>')
      end

      it "labels a very high label score as Very High" do
        expect(rendered_page.body).to include('for="lb-score-amazing">Very High</label>')
      end

      it "renders a tags column in the table controller" do
        expect(generated_content_table_controller).to include(%(scope="col">Tags</th>))
      end

      it "sends selected tags as the status filter" do
        expect(generated_content_table_controller).to include("params.set('status', this.tagsValue);")
      end

      it "reads the needs review flag" do
        expect(generated_content_table_controller).to include("record.needs_review")
      end

      it "reads the expired flag" do
        expect(generated_content_table_controller).to include("record.expired")
      end

      it "labels a very high score in green" do
        expect(generated_content_table_controller).to include("label = 'Very High'; colour = 'green'")
      end

      it "labels a low score in grey" do
        expect(generated_content_table_controller).to include("label = 'Low'; colour = 'grey'")
      end

      it "hides the labels tab panel" do
        expect(rendered_page.body).to include('govuk-tabs__panel govuk-tabs__panel--hidden" id="labels"')
      end

      it "hides the compressed notes tab panel" do
        expect(rendered_page.body).to include('govuk-tabs__panel govuk-tabs__panel--hidden" id="compressed-notes"')
      end

      it "loads the selected tab on click" do
        expect(rendered_page.body).to include('govuk-tabs__list" data-action="click->generated-content-tabs#loadSelectedTab"')
      end

      it "skips a table that is loaded or hidden" do
        expect(generated_content_table_controller).to include("if (this.loaded || !this.visible()) return;")
      end

      it "finds the clicked tab" do
        expect(generated_content_tabs_controller).to include("event.target.closest('.govuk-tabs__tab')")
      end

      it "waits before the selected tab loads" do
        expect(generated_content_tabs_controller).to include("window.setTimeout")
      end

      it "loads the selected table once" do
        expect(generated_content_tabs_controller).to include("controller.loadOnce();")
      end

      stylesheet = Rails.root.join("app/assets/stylesheets/application.sass.scss").read

      it "defines a fixed layout for the self-text table styles" do
        expect(stylesheet).to match(/\.self-text-table\s*\{[\s\S]*table-layout:\s*fixed;/)
      end

      it "defines wrapping styles for long self-text content" do
        expect(stylesheet).to match(/\.self-text-table\s*\{[\s\S]*&__description\s*\{[\s\S]*overflow-wrap:\s*anywhere;[\s\S]*word-break:\s*break-word;/)
      end

      it "defines a fixed layout for the labels table styles" do
        expect(stylesheet).to match(/\.label-table\s*\{[\s\S]*table-layout:\s*fixed;/)
      end

      it "defines wrapping styles for long label descriptions" do
        expect(stylesheet).to match(/\.label-table\s*\{[\s\S]*&__description\s*\{[\s\S]*overflow-wrap:\s*anywhere;[\s\S]*word-break:\s*break-word;/)
      end
    end

    context "with JSON format" do
      let(:make_request) { get goods_nomenclature_self_texts_path(format: :json) }

      before do
        stub_api_request("/goods_nomenclature_self_texts", backend: "uk")
          .with(query: hash_including({}))
          .and_return(collection_response)
      end

      it { is_expected.to have_http_status :success }

      it "returns an array of self-texts" do
        expect(index_json["data"]).to be_an(Array)
      end

      it "returns the commodity code" do
        expect(index_json["data"].first["goods_nomenclature_item_id"]).to eq(commodity_code)
      end

      it "returns the score" do
        expect(index_json["data"].first["score"]).to eq(0.70)
      end

      it "returns pagination data" do
        expect(index_json["pagination"]).to include("page", "total_count", "total_pages")
      end
    end

    context "with JSON format when the API fails" do
      let(:make_request) { get goods_nomenclature_self_texts_path(format: :json) }

      before do
        stub_api_request("/goods_nomenclature_self_texts", backend: "uk")
          .with(query: hash_including({}))
          .and_return(collection_response)
        stub_api_request("/goods_nomenclature_self_texts", backend: "uk")
          .with(query: hash_including({}))
          .and_return(status: 500, body: { error: "Internal Server Error" }.to_json)
      end

      it { is_expected.to have_http_status :success }

      it "returns empty data" do
        expect(index_json["data"]).to eq([])
      end
    end
  end

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

    it "displays the commodity code" do
      expect(rendered_page.body).to include(commodity_code)
    end

    it "displays the self-text content" do
      expect(rendered_page.body).to include("Live horses for breeding or racing purposes")
    end

    it "displays the save changes button" do
      expect(rendered_page.body).to include("Save changes")
    end

    it "displays the View labels cross-link when has_label is true" do
      expect(rendered_page.body).to include("View labels")
    end

    it "displays the created and updated dates" do
      expect(rendered_page.body).to include("Created", "15 June 2025", "Last updated", "Today")
    end

    it "does not show a record dates heading" do
      expect(rendered_page.body).not_to include("Record dates")
    end

    it "does not label the date as Created:" do
      expect(rendered_page.body).not_to include("Created:")
    end

    it "does not label the date as Updated:" do
      expect(rendered_page.body).not_to include("Updated:")
    end

    it "labels the state summary as tags" do
      expect(rendered_page.body).to include(%(<dt class="govuk-summary-list__key">Tags</dt>))
    end

    context "when the self-text has approved and expired tags" do
      let(:self_text_attributes) { super().merge("approved" => true, "expired" => true) }

      it "displays the approved tag" do
        expect(rendered_page.body).to include("Approved")
      end

      it "displays the expired tag" do
        expect(rendered_page.body).to include("Expired")
      end
    end

    context "when has_label is false" do
      let(:self_text_attributes) { super().merge("has_label" => false) }

      it "does not display the View labels cross-link" do
        expect(rendered_page.body).not_to include("View labels")
      end
    end

    context "when viewing a historical version via oid" do
      let(:make_request) { get goods_nomenclature_self_text_path(goods_nomenclature_sid, oid: "42") }

      def historical_self_text_response
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

      it "does not show generate score" do
        expect(rendered_page.body).not_to include("Generate score")
      end

      it "does not show regenerate self-text" do
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

      it { is_expected.to have_http_status :unprocessable_content }
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
