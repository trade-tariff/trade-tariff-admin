# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations, RSpec/MultipleMemoizedHelpers
RSpec.describe EvaluationRunsController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator, uid: "user-123") }
  let(:experiment_attributes) { { "name" => "Baseline", "configuration_overrides" => {}, "gold_query_set_id" => 3 } }
  let(:gold_query_set_attributes) { { "name" => "Set A", "atar_count" => 5, "synthetic_atar_count" => 0 } }
  let(:configuration_response) do
    {
      status: 200,
      headers: json_headers,
      body: {
        baseline: { "question_model" => "gpt-5.4", "max_rounds" => 7 },
        allowed_overrides: [
          { name: "question_model", config_type: "options", options: [{ key: "gpt-5.4", label: "gpt-5.4" }, { key: "gpt-5.6", label: "gpt-5.6" }] },
          { name: "max_rounds", config_type: "integer", min: 1, max: 20 },
          { name: "search_non_declarables", config_type: "boolean" },
        ],
      }.to_json,
    }
  end
  let(:json_headers) { { "content-type" => "application/json; charset=utf-8" } }

  def paginated_response(rows, type:, total_count: rows.length)
    {
      status: 200,
      headers: json_headers,
      body: {
        data: rows.map { |attributes| { type:, id: attributes["resource_id"], attributes: attributes.except("resource_id") } },
        meta: { pagination: { page: 1, per_page: 20, total_count: } },
      }.to_json,
    }
  end

  describe "GET #new" do
    let(:make_request) { get new_evaluation_run_path }

    before do
      stub_api_request("/search/evaluation/experiments").with(query: hash_including("per_page" => "200")).and_return(paginated_response([experiment_attributes.merge("resource_id" => "7")], type: "experiment"))
      stub_api_request("/search/evaluation/gold_query_sets").with(query: hash_including("per_page" => "200")).and_return(paginated_response([gold_query_set_attributes.merge("resource_id" => "3")], type: "gold_query_set"))
      stub_api_request("/search/evaluation/configuration").and_return(configuration_response)
    end

    it { is_expected.to have_http_status :success }

    it "shows the form with a field for every allowed override" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h1", text: "Launch an evaluation")
      expect(page).to have_select("Experiment", options: ["Choose an experiment", "Baseline"])
      expect(page).not_to have_select("Gold query set")
      expect(page).to have_select("Question model")
      expect(page).to have_field("Max rounds")
      expect(page).to have_css("fieldset", text: "Search non declarables")
      expect(page).to have_button("Launch")
    end

    it "embeds the experiment's gold query set name and item count in the preview data" do
      page = Capybara.string(rendered_page.body)
      experiments_data = JSON.parse(page.find("form")["data-run-preview-experiments-value"])

      expect(experiments_data.dig("7", "gold_query_set_name")).to eq("Set A")
      expect(experiments_data.dig("7", "gold_query_set_item_count")).to eq(5)
    end

    context "when the experiment's gold query set has been deleted" do
      before { stub_api_request("/search/evaluation/gold_query_sets").with(query: hash_including("per_page" => "200")).and_return(paginated_response([], type: "gold_query_set")) }

      it "still shows the form, without crashing" do
        expect(rendered_page).to have_http_status :success
      end
    end

    it "carries a freshly generated idempotency key as a hidden field" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("input[name='evaluation_run[idempotency_key]']", visible: false)
    end

    context "with ?experiment_id= given" do
      let(:make_request) { get new_evaluation_run_path(experiment_id: "7") }

      it "preselects that experiment" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_select("Experiment", selected: "Baseline")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end

    context "when the backend cannot be reached" do
      before { stub_api_request("/search/evaluation/configuration").to_raise(Faraday::ConnectionFailed) }

      it "redirects to the experiment list with a warning instead of an error page" do
        expect(rendered_page).to redirect_to(evaluation_experiments_path)

        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("The launch form could not be loaded. Try again.")
      end
    end
  end

  describe "POST #create" do
    let(:make_request) do
      post evaluation_runs_path, params: {
        evaluation_run: {
          experiment_id: "7",
          gold_query_set_id: "3",
          idempotency_key: "key-abc",
          max_rounds: "3",
          question_model: "",
          search_non_declarables: "",
        },
      }
    end

    context "when the backend accepts it" do
      before do
        stub_api_request("/search/evaluation/configuration").and_return(configuration_response)
        stub_api_request("/search/evaluation/runs", :post)
          .with { |request|
            attributes = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            request.headers["Idempotency-Key"] == "key-abc" &&
              attributes["configuration_overrides"] == { "max_rounds" => "3" }
          }
          .and_return(jsonapi_response("run", { "status" => "queued" }, status: 201).tap { |r| r[:body] = JSON.parse(r[:body]).deep_merge("data" => { "id" => "9" }).to_json })
      end

      it { is_expected.to redirect_to(evaluation_run_path("9")) }
    end

    context "when the backend rejects it" do
      before do
        stub_api_request("/search/evaluation/runs", :post).and_return(api_error_response(max_rounds: "must be between 1 and 20"))
        stub_api_request("/search/evaluation/experiments").with(query: hash_including("per_page" => "200")).and_return(paginated_response([experiment_attributes.merge("resource_id" => "7")], type: "experiment"))
        stub_api_request("/search/evaluation/gold_query_sets").with(query: hash_including("per_page" => "200")).and_return(paginated_response([gold_query_set_attributes.merge("resource_id" => "3")], type: "gold_query_set"))
        stub_api_request("/search/evaluation/configuration").and_return(configuration_response)
      end

      it { is_expected.to have_http_status :unprocessable_content }

      it "shows the error and keeps the same idempotency key" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css(".govuk-error-summary", text: "must be between 1 and 20")
        expect(page).to have_css("input[name='evaluation_run[idempotency_key]'][value='key-abc']", visible: false)
      end
    end

    context "when a boolean override is left on 'Use default'" do
      before do
        stub_api_request("/search/evaluation/configuration").and_return(configuration_response)
        stub_api_request("/search/evaluation/runs", :post)
          .with { |request| !Rack::Utils.parse_nested_query(request.body).dig("data", "attributes", "configuration_overrides")&.key?("search_non_declarables") }
          .and_return(jsonapi_response("run", { "status" => "queued", "resource_id" => "9" }, status: 201))
      end

      it "sends nothing for that key, not false" do
        expect(rendered_page).to have_http_status(:found)
      end
    end
  end

  describe "GET #show" do
    let(:make_request) { get evaluation_run_path(run_id) }
    let(:run_id) { "9" }
    let(:run_attributes) { { "experiment_id" => 7, "status" => "running", "gold_query_set_id" => 3, "result_count" => 4, "error_count" => 0 } }

    before do
      stub_api_request("/search/evaluation/runs/#{run_id}").and_return(jsonapi_response("run", run_attributes.merge("resource_id" => run_id)))
      stub_api_request("/search/evaluation/gold_query_sets/3").and_return(jsonapi_response("gold_query_set", { "name" => "Set A", "atar_count" => 10, "synthetic_atar_count" => 0, "resource_id" => "3" }))
    end

    it { is_expected.to have_http_status :success }

    it "shows the live count and a cancel button while the run is in progress" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("p", text: "4 of 10")
      expect(page).to have_button("Cancel run")
    end

    context "when the run has finished" do
      let(:run_attributes) { super().merge("status" => "completed", "result_count" => 10) }

      it "does not show a cancel button" do
        expect(Capybara.string(rendered_page.body)).not_to have_button("Cancel run")
      end
    end

    context "when the run has failed to start" do
      let(:run_attributes) { super().merge("status" => "failed", "result_count" => 0, "error_summary" => "could not reach the evaluation service: connection refused") }

      it "shows the error_summary, not just the bare status" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("p", text: "could not reach the evaluation service: connection refused")
      end
    end

    context "with the polling JSON response" do
      let(:make_request) { get evaluation_run_path(run_id, format: :json) }

      it "says the run is still pending while queued or running" do
        expect(JSON.parse(rendered_page.body)["pending"]).to be(true)
      end
    end

    context "with the polling JSON response, when the run has finished" do
      let(:make_request) { get evaluation_run_path(run_id, format: :json) }
      let(:run_attributes) { super().merge("status" => "completed") }

      it "says the run is no longer pending" do
        expect(JSON.parse(rendered_page.body)["pending"]).to be(false)
      end
    end

    context "when the backend cannot be reached" do
      before { stub_api_request("/search/evaluation/runs/#{run_id}").to_raise(Faraday::ConnectionFailed) }

      it "redirects to the experiment list with a warning instead of an error page" do
        expect(rendered_page).to redirect_to(evaluation_experiments_path)

        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("The launch form could not be loaded. Try again.")
      end
    end
  end

  describe "POST #cancel" do
    let(:make_request) { post cancel_evaluation_run_path(run_id) }
    let(:run_id) { "9" }

    before { stub_api_request("/search/evaluation/runs/#{run_id}").and_return(jsonapi_response("run", { "status" => "running", "resource_id" => run_id })) }

    context "when the run is still running" do
      before do
        stub_api_request("/search/evaluation/runs/#{run_id}", :patch)
          .with { |request| Rack::Utils.parse_nested_query(request.body).dig("data", "attributes", "status") == "cancelled" }
          .and_return(jsonapi_response("run", { "status" => "cancelled", "resource_id" => run_id }))
      end

      it { is_expected.to redirect_to(evaluation_run_path(run_id)) }
    end

    context "when the run has already finished" do
      before { stub_api_request("/search/evaluation/runs/#{run_id}").and_return(jsonapi_response("run", { "status" => "completed", "resource_id" => run_id })) }

      it "does nothing and redirects without sending a cancel request" do
        expect(rendered_page).to redirect_to(evaluation_run_path(run_id))
        expect(a_request(:patch, %r{/runs/#{run_id}})).not_to have_been_made
      end
    end
  end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations, RSpec/MultipleMemoizedHelpers
