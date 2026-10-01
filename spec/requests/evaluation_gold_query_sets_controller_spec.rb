# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations, RSpec/MultipleMemoizedHelpers
RSpec.describe EvaluationGoldQuerySetsController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }
  let(:set_id) { "3" }
  let(:json_headers) { { "content-type" => "application/json; charset=utf-8" } }
  let(:set_attributes) do
    {
      "name" => "Baseline",
      "requested_size" => 12,
      "atar_percentage" => 60,
      "planned_count" => 10,
      "generated_count" => 9,
      "failed_count" => 1,
      "status" => "partly_failed",
      "failures" => [{ "source_type" => "atar", "source_id" => "600000009", "error" => "the model did not return acceptable phrases after 3 attempts" }],
      "created_by" => "user-123",
      "created_at" => "2026-09-25T10:30:00Z",
      "atar_count" => 5,
      "synthetic_atar_count" => 4,
    }
  end
  let(:set_response) { jsonapi_response("gold_query_set", set_attributes.merge("resource_id" => set_id)) }

  let(:item_rows) do
    [
      {
        "resource_id" => "atar-600000001",
        "gold_query_set_id" => 3,
        "source_type" => "atar",
        "source_id" => "600000001",
        "real_user_search" => nil,
        "expected_code" => "6302100000",
        "oracle_text" => "Woven cotton bed linen.",
        "emu_generic_query" => "sheets",
        "emu_ordinary_query" => "cotton bed sheets",
        "emu_specific_query" => "printed cotton bed sheets",
      },
      {
        "resource_id" => "synthetic_atar-12",
        "gold_query_set_id" => 3,
        "source_type" => "synthetic_atar",
        "source_id" => "12",
        "real_user_search" => "a made up search",
        "expected_code" => "4201000000",
        "oracle_text" => "A leather riding saddle.",
        "emu_generic_query" => "saddle",
        "emu_ordinary_query" => "leather saddle",
        "emu_specific_query" => "leather riding saddle for a pony",
      },
    ]
  end

  def paginated_response(rows, total_count: rows.length, type: "gold_query_set")
    {
      status: 200,
      headers: json_headers,
      body: {
        data: rows.map { |attributes| { type: type, id: attributes["resource_id"], attributes: attributes.except("resource_id") } },
        meta: { pagination: { page: 1, per_page: 20, total_count: } },
      }.to_json,
    }
  end

  def stub_items(rows = item_rows)
    stub_api_request("/search/evaluation/gold_query_sets/#{set_id}/items")
      .and_return(paginated_response(rows, type: "gold_query_set_item"))
  end

  describe "GET #index" do
    let(:make_request) { get evaluation_gold_query_sets_path }

    before do
      create(:user, uid: "user-123", name: "Alex Example")
      stub_api_request("/search/evaluation/gold_query_sets")
        .and_return(paginated_response([set_attributes.merge("resource_id" => set_id)]))
    end

    it { is_expected.to have_http_status :success }

    context "when the XI service is selected" do
      before { allow(TradeTariffAdmin::ServiceChooser).to receive(:service_choice).and_return "xi" }

      it "is not reachable, even by going straight to the address" do
        expect(rendered_page).to have_http_status :not_found
      end
    end

    it "lists the sets with their status, progress and mix" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h1", text: "Gold query sets")
      expect(page).to have_css("caption", text: "1 gold query set")
      expect(page).to have_link("Baseline", href: evaluation_gold_query_set_path(set_id))
      expect(page).to have_css("strong.govuk-tag--yellow", text: "Partly failed")
      expect(page).to have_css("td", text: "10 of 10 done, 1 failed")
      expect(page).to have_css("td", text: "5 ATaR, 4 synthetic ATaR")
      expect(page).to have_css("td", text: "Alex Example")
      expect(page).to have_link("New gold query set", href: new_evaluation_gold_query_set_path)
    end

    context "when there are no sets" do
      before do
        stub_api_request("/search/evaluation/gold_query_sets").and_return(paginated_response([]))
      end

      it "says so" do
        expect(rendered_page.body).to include("No gold query sets yet.")
      end
    end

    context "when the backend cannot be reached" do
      before do
        stub_api_request("/search/evaluation/gold_query_sets").and_return(status: 400, headers: json_headers, body: { error: "bad request" }.to_json)
      end

      it "shows an empty list and a warning instead of an error page" do
        expect(rendered_page).to have_http_status(:success)
        expect(rendered_page.body).to include("Gold query sets could not be loaded. Try again.")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "GET #new" do
    let(:make_request) { get new_evaluation_gold_query_set_path }

    it "shows the form, with real ATaR rulings only as the starting mix" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h1", text: "New gold query set")
      expect(page).to have_field("Name")
      expect(page).to have_field("Number of source items")
      expect(page).to have_field("Percentage from real ATaR rulings", with: "100")
      expect(page).to have_button("Create gold query set")
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "POST #create" do
    let(:make_request) do
      post evaluation_gold_query_sets_path, params: {
        evaluation_gold_query_set: { name: "Baseline", requested_size: "12", atar_percentage: "60" },
      }
    end

    context "when the backend accepts it" do
      before do
        stub_api_request("/search/evaluation/gold_query_sets", :post)
          .with { |request|
            attributes = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            attributes.slice("name", "requested_size", "atar_percentage") == { "name" => "Baseline", "requested_size" => "12", "atar_percentage" => "60" }
          }
          .and_return(jsonapi_response("gold_query_set", set_attributes.merge("resource_id" => set_id, "status" => "generating"), status: 202))
      end

      it { is_expected.to redirect_to(evaluation_gold_query_set_path(set_id)) }

      it "explains that generation carries on in the background" do
        rendered_page

        expect(session.dig("flash", "flashes", "notice")).to eq("Gold query set created. It is being generated in the background.")
      end
    end

    context "when the backend rejects it" do
      before do
        stub_api_request("/search/evaluation/gold_query_sets", :post)
          .and_return(api_error_response(name: "is already taken"))
      end

      it { is_expected.to have_http_status :unprocessable_content }

      it "shows the error in the summary and on the field, and keeps what was typed" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css(".govuk-error-summary", text: "is already taken")
        expect(page).to have_css(".govuk-error-message", text: "is already taken")
        expect(page).to have_field("Name", with: "Baseline")
        expect(page).to have_field("Number of source items", with: "12")
        expect(page).to have_field("Percentage from real ATaR rulings", with: "60")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "GET #show" do
    let(:make_request) { get evaluation_gold_query_set_path(set_id) }

    before do
      create(:user, uid: "user-123", name: "Alex Example")
      stub_api_request("/search/evaluation/gold_query_sets/#{set_id}").and_return(set_response)
      stub_items
    end

    it { is_expected.to have_http_status :success }

    it "shows the set" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h1", text: "Baseline")
      expect(page).to have_css("strong.govuk-tag--yellow", text: "Partly failed")
      expect(page).to have_css(".govuk-summary-list__value", text: "60% ATaR rulings, 40% synthetic ATaRs")
      expect(page).to have_css(".govuk-summary-list__value", text: "12")
      expect(page).to have_css(".govuk-summary-list__value", text: "Alex Example")
      expect(page).to have_link("Delete gold query set", href: delete_evaluation_gold_query_set_path(set_id))
    end

    it "lists each item that failed, with its error" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h2", text: "Items that failed")
      expect(page).to have_css("td", text: "600000009")
      expect(page).to have_css("td", text: "the model did not return acceptable phrases after 3 attempts")
    end

    it "does not say the set is still generating" do
      expect(rendered_page.body).not_to include("still being generated")
    end

    it "lists each item with its source, code and three test searches" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h2", text: "Items")
      expect(page).to have_css("caption", text: "2 items")
      expect(page).to have_css("tr", text: "ATaR 600000001 6302100000 sheets cotton bed sheets printed cotton bed sheets", normalize_ws: true)
      expect(page).to have_css("tr", text: "Synthetic ATaR 12 Real search: a made up search 4201000000 saddle leather saddle leather riding saddle for a pony", normalize_ws: true)
    end

    it "links each item to its edit and delete pages" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_link("Edit", href: edit_evaluation_gold_query_set_item_path(set_id, "atar-600000001"))
      expect(page).to have_link("Delete", href: delete_evaluation_gold_query_set_item_path(set_id, "synthetic_atar-12"))
    end

    context "when the set has no items" do
      before { stub_items([]) }

      it "says so" do
        expect(rendered_page.body).to include("This set has no items.")
      end
    end

    context "when the items cannot be loaded" do
      before do
        stub_api_request("/search/evaluation/gold_query_sets/#{set_id}/items").and_return(status: 500, headers: json_headers, body: { error: "boom" }.to_json)
      end

      it "still shows the set, with a warning instead of the items" do
        expect(rendered_page).to have_http_status(:success)
        expect(rendered_page.body).to include("The items of this set could not be loaded. Try again.")
        expect(Capybara.string(rendered_page.body)).to have_css("h1", text: "Baseline")
      end
    end

    context "when the set is still generating" do
      let(:set_attributes) { super().merge("status" => "generating", "generated_count" => 4, "failed_count" => 0, "failures" => []) }

      it "says so, and how far it has got" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css(".govuk-notification-banner", text: "still being generated")
        expect(page).to have_css(".govuk-notification-banner", text: "4 of 10")
        expect(page).not_to have_css("h2", text: "Items that failed")
      end

      it "lists the items written so far but offers no edit or delete until it has finished" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("td", text: "6302100000")
        expect(page).not_to have_link("Edit")
        expect(page).not_to have_link("Delete", href: %r{/items/})
      end
    end

    context "when the set does not exist" do
      before do
        stub_api_request("/search/evaluation/gold_query_sets/#{set_id}").and_return(status: 404, headers: json_headers, body: { errors: [{ detail: "not found" }] }.to_json)
      end

      it { is_expected.to redirect_to(evaluation_gold_query_sets_path) }

      it "says so" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("Gold query set not found.")
      end
    end

    context "when the backend is down or slow" do
      before do
        stub_api_request("/search/evaluation/gold_query_sets/#{set_id}").to_raise(Faraday::ConnectionFailed)
      end

      it { is_expected.to redirect_to(evaluation_gold_query_sets_path) }

      it "shows a warning instead of an error page" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("The gold query set could not be loaded. Try again.")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "GET #confirm_destroy" do
    let(:make_request) { get delete_evaluation_gold_query_set_path(set_id) }

    before do
      stub_api_request("/search/evaluation/gold_query_sets/#{set_id}").and_return(set_response)
    end

    it "asks for confirmation and says what will be lost" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h1", text: "Are you sure you want to delete this gold query set?")
      expect(page).to have_css(".govuk-warning-text", text: "all of its gold queries and their history")
      expect(page).to have_text("Baseline")
      expect(page).to have_button("Delete gold query set")
    end
  end

  describe "DELETE #destroy" do
    let(:make_request) { delete evaluation_gold_query_set_path(set_id) }

    before do
      stub_api_request("/search/evaluation/gold_query_sets/#{set_id}").and_return(set_response)
    end

    context "when the backend deletes it" do
      before do
        stub_api_request("/search/evaluation/gold_query_sets/#{set_id}", :delete).and_return(status: 204, headers: json_headers, body: nil)
      end

      it { is_expected.to redirect_to(evaluation_gold_query_sets_path) }

      it "confirms the deletion" do
        rendered_page

        expect(session.dig("flash", "flashes", "notice")).to eq("Gold query set deleted successfully.")
      end
    end

    context "when an experiment still uses the set" do
      before do
        stub_api_request("/search/evaluation/gold_query_sets/#{set_id}", :delete).and_return(
          status: 409,
          headers: json_headers,
          body: { errors: [{ status: "409", title: "Gold query set is in use", detail: "This set cannot be deleted because these experiments use it: baseline. Point them at another set first." }] }.to_json,
        )
      end

      it { is_expected.to redirect_to(evaluation_gold_query_set_path(set_id)) }

      it "shows the backend's reason, which names the experiments" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("This set cannot be deleted because these experiments use it: baseline. Point them at another set first.")
      end
    end
  end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations, RSpec/MultipleMemoizedHelpers
