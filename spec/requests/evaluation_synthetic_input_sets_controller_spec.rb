RSpec.describe EvaluationSyntheticInputSetsController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }
  let(:set_id) { "9" }
  let(:set_attributes) do
    {
      "name" => "Baseline",
      "requested_size" => 10,
      "actual_size" => 8,
      "created_by" => "user-123",
      "created_at" => "2026-10-19T10:00:00Z",
    }
  end

  def json_headers
    { "content-type" => "application/json; charset=utf-8" }
  end

  def set_response
    jsonapi_response("synthetic_input_set", set_attributes.merge("resource_id" => set_id))
  end

  def item_rows
    [
      { "resource_id" => "1", "synthetic_input_set_id" => 9, "synthetic_atar_id" => 42, "query" => "Reusable plastic food storage box with a clip-on lid.", "expected_code" => "3924100000" },
      { "resource_id" => "2", "synthetic_input_set_id" => 9, "synthetic_atar_id" => 43, "query" => "Stainless steel vacuum-insulated water bottle.", "expected_code" => "9617001000" },
    ]
  end

  def paginated_response(rows, total_count: rows.length, type: "synthetic_input_set")
    {
      status: 200,
      headers: json_headers,
      body: {
        data: rows.map { |attributes| { type: type, id: attributes["resource_id"], attributes: attributes.except("resource_id") } },
        meta: { pagination: { page: 1, per_page: 20, total_count: } },
      }.to_json,
    }
  end

  def stub_items(rows = item_rows, total_count: rows.length)
    stub_api_request("/search/evaluation/synthetic_input_sets/#{set_id}/items")
      .and_return(paginated_response(rows, total_count:, type: "synthetic_input_set_item"))
  end

  def page
    Capybara.string(rendered_page.body)
  end

  describe "GET #index" do
    let(:make_request) { get evaluation_synthetic_input_sets_path }

    before do
      create(:user, uid: "user-123", name: "Alex Example")
      stub_api_request("/search/evaluation/synthetic_input_sets")
        .and_return(paginated_response([set_attributes.merge("resource_id" => set_id)]))
    end

    it { is_expected.to have_http_status :success }

    context "when the XI service is selected" do
      before { allow(TradeTariffAdmin::ServiceChooser).to receive(:service_choice).and_return "xi" }

      it "is not reachable, even by going straight to the address" do
        expect(rendered_page).to have_http_status :not_found
      end
    end

    it "shows the heading" do
      expect(page).to have_css("h1", text: "Synthetic input sets")
    end

    it "marks Synthetic Input Sets as the current evaluation tab" do
      expect(page).to have_css("nav.app-sub-navigation[aria-label='Evaluation'] a[aria-current='page']", text: "Synthetic Input Sets")
    end

    it "points the Synthetic Input Sets tab at this list, so existing names can be checked first" do
      expect(page).to have_css("nav.app-sub-navigation[aria-label='Evaluation'] a[href='#{evaluation_synthetic_input_sets_path}']", text: "Synthetic Input Sets")
    end

    it "shows the set count" do
      expect(page).to have_css("caption", text: "1 synthetic input set")
    end

    it "links to the set" do
      expect(page).to have_link("Baseline", href: evaluation_synthetic_input_set_path(set_id))
    end

    it "shows how many items were asked for" do
      expect(page).to have_css("td", exact_text: "10")
    end

    it "shows how many items were sampled" do
      expect(page).to have_css("td", exact_text: "8")
    end

    it "shows the creator" do
      expect(page).to have_css("td", exact_text: "Alex Example")
    end

    it "links to a new synthetic input set" do
      expect(page).to have_link("New synthetic input set", href: new_evaluation_synthetic_input_set_path)
    end

    context "when there are no sets" do
      before do
        stub_api_request("/search/evaluation/synthetic_input_sets").and_return(paginated_response([]))
      end

      it "says so" do
        expect(rendered_page.body).to include("No synthetic input sets yet.")
      end
    end

    context "when the backend cannot be reached" do
      before do
        stub_api_request("/search/evaluation/synthetic_input_sets").and_return(status: 400, headers: json_headers, body: { error: "bad request" }.to_json)
      end

      it "returns success" do
        expect(rendered_page).to have_http_status(:success)
      end

      it "warns that sets could not be loaded" do
        expect(rendered_page.body).to include("Synthetic input sets could not be loaded. Try again.")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "GET #new" do
    let(:make_request) { get new_evaluation_synthetic_input_set_path }

    it "shows the heading" do
      expect(page).to have_css("h1", text: "New synthetic input set")
    end

    it "shows the name field" do
      expect(page).to have_field("Name")
    end

    it "shows the size field" do
      expect(page).to have_field("Number of source items")
    end

    it "shows the create button" do
      expect(page).to have_button("Create synthetic input set")
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "POST #create" do
    let(:make_request) do
      post evaluation_synthetic_input_sets_path, params: {
        evaluation_synthetic_input_set: { name: "Baseline", requested_size: "10" },
      }
    end

    context "when the backend accepts it" do
      before do
        stub_api_request("/search/evaluation/synthetic_input_sets", :post)
          .with { |request|
            attributes = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            attributes == { "name" => "Baseline", "requested_size" => "10" }
          }
          .and_return(jsonapi_response("synthetic_input_set", set_attributes.merge("resource_id" => set_id), status: 201))
      end

      it { is_expected.to redirect_to(evaluation_synthetic_input_set_path(set_id)) }

      it "confirms the set was created" do
        rendered_page

        expect(session.dig("flash", "flashes", "notice")).to eq("Synthetic input set created.")
      end
    end

    context "when the backend rejects it" do
      before do
        stub_api_request("/search/evaluation/synthetic_input_sets", :post).and_return(api_error_response(name: "is already taken"))
      end

      it { is_expected.to have_http_status :unprocessable_content }

      it "shows the error in the summary" do
        expect(page).to have_css(".govuk-error-summary", text: "is already taken")
      end

      it "keeps the typed name" do
        expect(page).to have_field("Name", with: "Baseline")
      end

      it "keeps the typed size" do
        expect(page).to have_field("Number of source items", with: "10")
      end
    end

    context "when the backend cannot be reached" do
      before { stub_api_request("/search/evaluation/synthetic_input_sets", :post).and_return(status: 500, headers: json_headers, body: { error: "boom" }.to_json) }

      it "redirects to the new set form" do
        expect(rendered_page).to redirect_to(new_evaluation_synthetic_input_set_path)
      end

      it "warns that the set could not be created" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("The synthetic input set could not be created. Try again.")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "GET #show" do
    let(:make_request) { get evaluation_synthetic_input_set_path(set_id) }

    before do
      create(:user, uid: "user-123", name: "Alex Example")
      stub_api_request("/search/evaluation/synthetic_input_sets/#{set_id}").and_return(set_response)
      stub_items
    end

    it { is_expected.to have_http_status :success }

    it "shows the name" do
      expect(page).to have_css("h1", text: "Baseline")
    end

    it "shows how many items were asked for" do
      expect(page).to have_css(".govuk-summary-list__row", text: /Items asked for\s+10\b/)
    end

    it "shows how many items were actually sampled" do
      expect(page).to have_css(".govuk-summary-list__row", text: /Items sampled\s+8\b/)
    end

    it "shows the creator" do
      expect(page).to have_css(".govuk-summary-list__value", text: "Alex Example")
    end

    it "links to delete the set" do
      expect(page).to have_link("Delete synthetic input set", href: delete_evaluation_synthetic_input_set_path(set_id))
    end

    it "shows the item count" do
      expect(page).to have_css("caption", text: "2 items")
    end

    it "shows each item's synthetic ATaR" do
      expect(page).to have_css("td", exact_text: "42")
    end

    it "shows each item's query" do
      expect(page).to have_css("td", text: "Reusable plastic food storage box with a clip-on lid.")
    end

    it "shows each item's expected code" do
      expect(page).to have_css("td", text: "3924100000")
    end

    it "offers no edit on an item, because a set's contents are fixed" do
      expect(page).not_to have_link("Edit")
    end

    it "offers no delete on an item, because a set's contents are fixed" do
      expect(page).not_to have_link("Delete", href: %r{/items/})
    end

    context "when the set has more items than fit on one page" do
      before { stub_items(item_rows, total_count: 45) }

      it "shows the size of the whole set" do
        expect(page).to have_css("caption", text: "45 items")
      end

      it "links to the next page of items" do
        expect(page).to have_link("2", href: evaluation_synthetic_input_set_path(set_id, page: 2))
      end
    end

    context "when asking for the second page" do
      let(:make_request) { get evaluation_synthetic_input_set_path(set_id, page: 2) }

      before do
        stub_api_request("/search/evaluation/synthetic_input_sets/#{set_id}/items")
          .with(query: { page: "2" })
          .and_return(paginated_response([item_rows.last], total_count: 21, type: "synthetic_input_set_item"))
      end

      it "shows the items of that page" do
        expect(page).to have_css("td", text: "9617001000")
      end
    end

    context "when the set has no items" do
      before { stub_items([]) }

      it "says so" do
        expect(rendered_page.body).to include("This set has no items.")
      end
    end

    context "when the items cannot be loaded" do
      before do
        stub_api_request("/search/evaluation/synthetic_input_sets/#{set_id}/items").and_return(status: 500, headers: json_headers, body: { error: "boom" }.to_json)
      end

      it "returns success" do
        expect(rendered_page).to have_http_status(:success)
      end

      it "warns that the items could not be loaded" do
        expect(rendered_page.body).to include("The items of this set could not be loaded. Try again.")
      end

      it "still shows the set" do
        expect(page).to have_css("h1", text: "Baseline")
      end
    end

    context "when the set does not exist" do
      before do
        stub_api_request("/search/evaluation/synthetic_input_sets/#{set_id}").and_return(status: 404, headers: json_headers, body: { errors: [{ detail: "not found" }] }.to_json)
      end

      it { is_expected.to redirect_to(evaluation_synthetic_input_sets_path) }

      it "says so" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("Synthetic input set not found.")
      end
    end

    context "when the backend is down or slow" do
      before do
        stub_api_request("/search/evaluation/synthetic_input_sets/#{set_id}").to_raise(Faraday::ConnectionFailed)
      end

      it { is_expected.to redirect_to(evaluation_synthetic_input_sets_path) }

      it "says the set could not be loaded" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("The synthetic input set could not be loaded. Try again.")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "GET #confirm_destroy" do
    let(:make_request) { get delete_evaluation_synthetic_input_set_path(set_id) }

    before do
      stub_api_request("/search/evaluation/synthetic_input_sets/#{set_id}").and_return(set_response)
    end

    it "asks for confirmation" do
      expect(page).to have_css("h1", text: "Are you sure you want to delete this synthetic input set?")
    end

    it "says what will be lost" do
      expect(page).to have_css(".govuk-warning-text", text: "all of its items")
    end

    it "shows the set name" do
      expect(page).to have_text("Baseline")
    end

    it "shows the delete button" do
      expect(page).to have_button("Delete synthetic input set")
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "DELETE #destroy" do
    let(:make_request) { delete evaluation_synthetic_input_set_path(set_id) }

    before do
      stub_api_request("/search/evaluation/synthetic_input_sets/#{set_id}").and_return(set_response)
    end

    context "when the backend deletes it" do
      before do
        stub_api_request("/search/evaluation/synthetic_input_sets/#{set_id}", :delete).and_return(status: 204, headers: json_headers, body: nil)
      end

      it { is_expected.to redirect_to(evaluation_synthetic_input_sets_path) }

      it "confirms the deletion" do
        rendered_page

        expect(session.dig("flash", "flashes", "notice")).to eq("Synthetic input set deleted successfully.")
      end
    end

    context "when an experiment still uses the set" do
      before do
        stub_api_request("/search/evaluation/synthetic_input_sets/#{set_id}", :delete).and_return(
          status: 409,
          headers: json_headers,
          body: { errors: [{ status: "409", title: "Synthetic input set is in use", detail: "This set cannot be deleted because these experiments use it: baseline. Point them at another set first." }] }.to_json,
        )
      end

      it { is_expected.to redirect_to(evaluation_synthetic_input_set_path(set_id)) }

      it "shows the backend's reason, which names the experiments" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("This set cannot be deleted because these experiments use it: baseline. Point them at another set first.")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end
end
