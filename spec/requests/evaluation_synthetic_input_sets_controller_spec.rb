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
      "items" => [
        { "id" => "1", "synthetic_atar_id" => 42, "query" => "Reusable plastic food storage box with a clip-on lid.", "expected_code" => "3924100000" },
        { "id" => "2", "synthetic_atar_id" => 43, "query" => "Stainless steel vacuum-insulated water bottle.", "expected_code" => "9617001000" },
      ],
    }
  end

  def json_headers
    { "content-type" => "application/json; charset=utf-8" }
  end

  def page
    Capybara.string(rendered_page.body)
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

      it { is_expected.to have_http_status :success }

      it "shows the created set's name, without a redirect, since there is nothing more to wait for" do
        expect(page).to have_css("h1", text: "Baseline")
      end

      it "shows how many items were actually sampled" do
        expect(page).to have_css(".govuk-summary-list__value", text: "8")
      end

      it "shows the item count" do
        expect(page).to have_css("caption", text: "2 items")
      end

      it "shows each item's query" do
        expect(page).to have_css("td", text: "Reusable plastic food storage box with a clip-on lid.")
      end

      it "shows each item's expected code" do
        expect(page).to have_css("td", text: "3924100000")
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
end
