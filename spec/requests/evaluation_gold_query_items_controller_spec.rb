# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations, RSpec/MultipleMemoizedHelpers
RSpec.describe EvaluationGoldQueryItemsController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }
  let(:set_id) { "3" }
  let(:item_id) { "synthetic_atar-12" }
  let(:item_path) { "/search/evaluation/gold_query_sets/#{set_id}/items/#{item_id}" }
  let(:json_headers) { { "content-type" => "application/json; charset=utf-8" } }
  let(:item_attributes) do
    {
      "gold_query_set_id" => 3,
      "source_type" => "synthetic_atar",
      "source_id" => "12",
      "real_user_search" => "a made up search",
      "expected_code" => "6302100000",
      "oracle_text" => "Woven cotton bed linen with a printed floral pattern.",
      "emu_generic_query" => "sheets",
      "emu_generic_notes" => nil,
      "emu_ordinary_query" => "cotton bed sheets",
      "emu_ordinary_notes" => nil,
      "emu_specific_query" => "printed cotton bed sheets",
      "emu_specific_notes" => "checked with the analysts",
    }
  end
  let(:item_response) { jsonapi_response("gold_query_set_item", item_attributes.merge("resource_id" => item_id)) }
  let(:versions_response) do
    {
      status: 200,
      headers: json_headers,
      body: {
        data: [
          {
            id: "31",
            type: "version",
            attributes: {
              "item_type" => "EvaluationGoldQuery",
              "item_id" => "5",
              "event" => "update",
              "whodunnit" => nil,
              "created_at" => "2026-09-25T11:00:00Z",
              "object" => { "persona" => "emu_generic", "query" => "sheets" },
              "changeset" => { "changed_fields" => %w[query], "changes" => { "query" => { "type" => "simple", "old" => "bed sheets", "new" => "sheets" } } },
            },
          },
          {
            id: "30",
            type: "version",
            attributes: {
              "item_type" => "EvaluationGoldQuery",
              "item_id" => "5",
              "event" => "create",
              "whodunnit" => "user-123",
              "created_at" => "2026-09-25T10:30:00Z",
              "object" => { "persona" => "emu_generic", "query" => "bed sheets" },
            },
          },
        ],
      }.to_json,
    }
  end

  before do
    stub_api_request("/search/evaluation/gold_query_sets/#{set_id}")
      .and_return(jsonapi_response("gold_query_set", { "resource_id" => set_id, "name" => "Baseline", "status" => "ready" }))
    stub_api_request(item_path).and_return(item_response)
    stub_api_request("#{item_path}/versions").and_return(versions_response)
  end

  describe "GET #edit" do
    let(:make_request) { get edit_evaluation_gold_query_set_item_path(set_id, item_id) }

    it { is_expected.to have_http_status :success }

    it "shows where the item came from and the text the test searches were written from" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h1", text: "Edit test searches")
      expect(page).to have_css(".govuk-summary-list__value", text: "Synthetic ATaR")
      expect(page).to have_css(".govuk-summary-list__value", text: "a made up search")
      expect(page).to have_css(".govuk-summary-list__value", text: "Woven cotton bed linen with a printed floral pattern.")
      expect(page).to have_link("Cancel", href: evaluation_gold_query_set_path(set_id))
      expect(page).to have_link("Baseline", href: evaluation_gold_query_set_path(set_id))
    end

    it "fills the form with the current values" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_field("Expected commodity code", with: "6302100000")
      expect(page).to have_field("Generic search", with: "sheets")
      expect(page).to have_field("Ordinary search", with: "cotton bed sheets")
      expect(page).to have_field("Specific search", with: "printed cotton bed sheets")
      expect(page).to have_field("Notes on the specific search", with: "checked with the analysts")
      expect(page).to have_button("Save changes")
    end

    it "shows the history of the item's three rows, read only" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h2", text: "History")
      expect(page).to have_css("td", text: "Generic search")
      expect(page).to have_css("td", text: "Changed: Query")
      expect(page).to have_css("td", text: "Initial version")
      expect(page).not_to have_button("Restore")
    end

    context "when the item came from an ATaR" do
      let(:item_attributes) { super().merge("source_type" => "atar", "source_id" => "600000001", "real_user_search" => nil) }
      let(:item_id) { "atar-600000001" }

      it "does not show a real user search" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css(".govuk-summary-list__value", text: "ATaR")
        expect(page).not_to have_css(".govuk-summary-list__key", text: "Real user search")
      end
    end

    context "when the history cannot be loaded" do
      before do
        stub_api_request("#{item_path}/versions").and_return(status: 500, headers: json_headers, body: { error: "boom" }.to_json)
      end

      it "still shows the form" do
        expect(rendered_page).to have_http_status(:success)
        expect(Capybara.string(rendered_page.body)).to have_field("Generic search", with: "sheets")
      end
    end

    context "when the item does not exist" do
      before do
        stub_api_request(item_path).and_return(status: 404, headers: json_headers, body: { errors: [{ detail: "not found" }] }.to_json)
      end

      it { is_expected.to redirect_to(evaluation_gold_query_set_path(set_id)) }

      it "says so" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("Gold query set item not found.")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "PATCH #update" do
    let(:make_request) do
      patch evaluation_gold_query_set_item_path(set_id, item_id), params: {
        evaluation_gold_query_item: {
          expected_code: "6302100090",
          emu_generic_query: "cotton sheets",
          emu_generic_notes: "",
          emu_ordinary_query: "cotton bed sheets",
          emu_specific_query: "printed cotton bed sheets",
        },
      }
    end

    context "when the backend accepts it" do
      before do
        stub_api_request(item_path, :patch)
          .with { |request|
            attributes = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            attributes.slice("expected_code", "emu_generic_query") == { "expected_code" => "6302100090", "emu_generic_query" => "cotton sheets" }
          }
          .and_return(item_response)
      end

      it { is_expected.to redirect_to(evaluation_gold_query_set_path(set_id)) }

      it "confirms the change" do
        rendered_page

        expect(session.dig("flash", "flashes", "notice")).to eq("Test searches updated successfully.")
      end
    end

    context "when the backend rejects it" do
      before do
        stub_api_request(item_path, :patch)
          .and_return(api_error_response(emu_generic_query: "is not present", expected_code: "must be 6, 8 or 10 digits"))
      end

      it { is_expected.to have_http_status :unprocessable_content }

      it "shows each error on its field and keeps what was typed" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css(".govuk-error-summary", text: "must be 6, 8 or 10 digits")
        expect(page).to have_css(".govuk-error-message", text: "is not present")
        expect(page).to have_field("Expected commodity code", with: "6302100090")
        expect(page).to have_field("Generic search", with: "cotton sheets")
        expect(page).to have_css("h2", text: "History")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "GET #confirm_destroy" do
    let(:make_request) { get delete_evaluation_gold_query_set_item_path(set_id, item_id) }

    it "asks for confirmation and says what will be deleted" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h1", text: "Are you sure you want to delete this item?")
      expect(page).to have_css(".govuk-warning-text", text: "all three of its test searches")
      expect(page).to have_text("a made up search")
      expect(page).to have_text("printed cotton bed sheets")
      expect(page).to have_button("Delete item")
    end
  end

  describe "DELETE #destroy" do
    let(:make_request) { delete evaluation_gold_query_set_item_path(set_id, item_id) }

    before do
      stub_api_request(item_path, :delete).and_return(status: 204, headers: json_headers, body: nil)
    end

    it { is_expected.to redirect_to(evaluation_gold_query_set_path(set_id)) }

    it "confirms the deletion" do
      rendered_page

      expect(session.dig("flash", "flashes", "notice")).to eq("Item deleted successfully.")
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations, RSpec/MultipleMemoizedHelpers
