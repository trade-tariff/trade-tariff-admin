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
          { name: "question_model", config_type: "options", description: "The AI model used to ask clarifying questions.", options: [{ key: "gpt-5.4", label: "gpt-5.4" }, { key: "gpt-5.6", label: "gpt-5.6" }] },
          { name: "max_rounds", config_type: "integer", min: 1, max: 20, description: "The most clarifying questions the search can ask." },
          { name: "search_non_declarables", config_type: "boolean", description: "Include non-declarable codes in the results." },
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

    it "puts the overrides inside a collapsible accordion, so the page isn't a wall of fields" do
      page = Capybara.string(rendered_page.body)

      accordion = page.find(".govuk-accordion[data-module='govuk-accordion']")
      expect(accordion).to have_css(".govuk-accordion__section-button", text: "Overrides")
      expect(accordion).to have_select("Question model")
      expect(accordion).to have_field("Max rounds")
    end

    it "embeds the experiment's gold query set name and item count in the preview data" do
      page = Capybara.string(rendered_page.body)
      experiments_data = JSON.parse(page.find("form")["data-run-preview-experiments-value"])

      expect(experiments_data.dig("7", "gold_query_set_name")).to eq("Set A")
      expect(experiments_data.dig("7", "gold_query_set_item_count")).to eq(5)
    end

    it "explains what each override does" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css(".govuk-hint", text: "The AI model used to ask clarifying questions.")
      expect(page).to have_css(".govuk-hint", text: "Include non-declarable codes in the results.")
    end

    it "tells the operator a number field can be left blank for the default, not just that an option exists" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css(".govuk-hint", text: "Leave blank to use the default.")
    end

    it "puts the live-preview target on each individual boolean radio, not just the fieldset" do
      page = Capybara.string(rendered_page.body)

      radios = page.all("input[type='radio'][data-override-key='search_non_declarables']")
      expect(radios.size).to eq(3)
      expect(radios.map { |radio| radio["data-run-preview-target"] }).to all(eq("overrideField"))
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
            attributes = JSON.parse(request.body).dig("data", "attributes")
            request.headers["Idempotency-Key"] == "key-abc" &&
              attributes["configuration_overrides"] == { "max_rounds" => 3 }
          }
          .and_return(jsonapi_response("run", { "status" => "queued" }, status: 201).tap { |r| r[:body] = JSON.parse(r[:body]).deep_merge("data" => { "id" => "9" }).to_json })
      end

      it { is_expected.to redirect_to(evaluation_run_path("9")) }
    end

    context "when a boolean override is set" do
      let(:make_request) do
        post evaluation_runs_path, params: {
          evaluation_run: {
            experiment_id: "7",
            gold_query_set_id: "3",
            idempotency_key: "key-abc",
            max_rounds: "",
            question_model: "",
            search_non_declarables: "true",
          },
        }
      end

      before do
        stub_api_request("/search/evaluation/configuration").and_return(configuration_response)
        stub_api_request("/search/evaluation/runs", :post)
          .with { |request|
            JSON.parse(request.body).dig("data", "attributes", "configuration_overrides") == { "search_non_declarables" => true }
          }
          .and_return(jsonapi_response("run", { "status" => "queued", "resource_id" => "9" }, status: 201))
      end

      it "sends a real boolean, not the string \"true\"" do
        expect(rendered_page).to have_http_status(:found)
      end
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

      it "also keeps the experiment selection and the typed override values" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_select("Experiment", selected: "Baseline")
        expect(page).to have_field("Max rounds", with: "3")
      end
    end

    context "when the backend rejects it and a model-select override was chosen" do
      let(:make_request) do
        post evaluation_runs_path, params: {
          evaluation_run: {
            experiment_id: "7",
            gold_query_set_id: "3",
            idempotency_key: "key-abc",
            max_rounds: "3",
            question_model: "gpt-5.6",
            search_non_declarables: "",
          },
        }
      end

      before do
        stub_api_request("/search/evaluation/runs", :post).and_return(api_error_response(max_rounds: "must be between 1 and 20"))
        stub_api_request("/search/evaluation/experiments").with(query: hash_including("per_page" => "200")).and_return(paginated_response([experiment_attributes.merge("resource_id" => "7")], type: "experiment"))
        stub_api_request("/search/evaluation/gold_query_sets").with(query: hash_including("per_page" => "200")).and_return(paginated_response([gold_query_set_attributes.merge("resource_id" => "3")], type: "gold_query_set"))
        stub_api_request("/search/evaluation/configuration").and_return(configuration_response)
      end

      it "keeps the chosen model selected, not reset to Use default" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_select("Question model", selected: "gpt-5.6")
      end
    end

    context "when the backend rejects it and a boolean override was chosen" do
      let(:make_request) do
        post evaluation_runs_path, params: {
          evaluation_run: {
            experiment_id: "7",
            gold_query_set_id: "3",
            idempotency_key: "key-abc",
            max_rounds: "3",
            question_model: "",
            search_non_declarables: "true",
          },
        }
      end

      before do
        stub_api_request("/search/evaluation/runs", :post).and_return(api_error_response(max_rounds: "must be between 1 and 20"))
        stub_api_request("/search/evaluation/experiments").with(query: hash_including("per_page" => "200")).and_return(paginated_response([experiment_attributes.merge("resource_id" => "7")], type: "experiment"))
        stub_api_request("/search/evaluation/gold_query_sets").with(query: hash_including("per_page" => "200")).and_return(paginated_response([gold_query_set_attributes.merge("resource_id" => "3")], type: "gold_query_set"))
        stub_api_request("/search/evaluation/configuration").and_return(configuration_response)
      end

      it "keeps the chosen radio checked, not reset to Use default" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_checked_field("Yes")
      end
    end

    context "when the eval run service cannot be reached at all" do
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

      before do
        stub_api_request("/search/evaluation/configuration").and_return(configuration_response)
        stub_api_request("/search/evaluation/experiments").with(query: hash_including("per_page" => "200")).and_return(paginated_response([experiment_attributes.merge("resource_id" => "7")], type: "experiment"))
        stub_api_request("/search/evaluation/gold_query_sets").with(query: hash_including("per_page" => "200")).and_return(paginated_response([gold_query_set_attributes.merge("resource_id" => "3")], type: "gold_query_set"))
        stub_api_request("/search/evaluation/runs", :post).to_raise(Faraday::ConnectionFailed)
      end

      it "shows the form again with a warning, instead of redirecting away" do
        expect(rendered_page).to have_http_status(:unprocessable_content)
      end

      it "keeps the same idempotency key and what was typed" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("input[name='evaluation_run[idempotency_key]'][value='key-abc']", visible: false)
        expect(page).to have_select("Experiment", selected: "Baseline")
        expect(page).to have_field("Max rounds", with: "3")
      end
    end

    context "when no experiment was chosen" do
      let(:make_request) do
        post evaluation_runs_path, params: {
          evaluation_run: {
            experiment_id: "",
            gold_query_set_id: "",
            idempotency_key: "key-abc",
            max_rounds: "",
            question_model: "",
            search_non_declarables: "",
          },
        }
      end

      before do
        stub_api_request("/search/evaluation/configuration").and_return(configuration_response)
        stub_api_request("/search/evaluation/experiments").with(query: hash_including("per_page" => "200")).and_return(paginated_response([experiment_attributes.merge("resource_id" => "7")], type: "experiment"))
        stub_api_request("/search/evaluation/gold_query_sets").with(query: hash_including("per_page" => "200")).and_return(paginated_response([gold_query_set_attributes.merge("resource_id" => "3")], type: "gold_query_set"))
      end

      it "shows a validation error instead of calling the backend at all" do
        expect(rendered_page).to have_http_status(:unprocessable_content)
        expect(a_request(:post, %r{/search/evaluation/runs\z})).not_to have_been_made
      end

      it "names the missing field" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css(".govuk-error-summary", text: "Choose an experiment")
      end
    end

    context "when this idempotency key was already used for a different request" do
      before do
        stub_api_request("/search/evaluation/configuration").and_return(configuration_response)
        stub_api_request("/search/evaluation/experiments").with(query: hash_including("per_page" => "200")).and_return(paginated_response([experiment_attributes.merge("resource_id" => "7")], type: "experiment"))
        stub_api_request("/search/evaluation/gold_query_sets").with(query: hash_including("per_page" => "200")).and_return(paginated_response([gold_query_set_attributes.merge("resource_id" => "3")], type: "gold_query_set"))
        stub_api_request("/search/evaluation/runs", :post).and_return(status: 409, headers: json_headers, body: { error: "conflict" }.to_json)
      end

      it "tells the operator to reload for a new attempt, not that the service is unreachable" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css(".govuk-error-summary", text: "A run was already started from this form")
      end
    end

    context "when a boolean override is left on 'Use default'" do
      before do
        stub_api_request("/search/evaluation/configuration").and_return(configuration_response)
        stub_api_request("/search/evaluation/runs", :post)
          .with { |request| !JSON.parse(request.body).dig("data", "attributes", "configuration_overrides")&.key?("search_non_declarables") }
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
      stub_api_request("/search/evaluation/gold_query_sets/3").and_return(jsonapi_response("gold_query_set", { "name" => "Set A", "atar_count" => 10, "synthetic_atar_count" => 0, "gold_query_count" => 30, "resource_id" => "3" }))
      stub_api_request("/search/evaluation/experiments/7").and_return(jsonapi_response("experiment", experiment_attributes.merge("resource_id" => "7")))
    end

    it { is_expected.to have_http_status :success }

    it "shows the experiment name alongside the run id, not just a bare number" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h1", text: "Baseline — Run ID: 9")
    end

    it "shows the live count and a cancel button while the run is in progress" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("p", text: "4 of 30")
      expect(page).to have_button("Cancel run")
    end

    it "has no back link while the run is still in progress, so a running run stays watched" do
      page = Capybara.string(rendered_page.body)

      expect(page).not_to have_css("a.govuk-back-link")
    end

    context "when enough of the run has finished to estimate the time remaining" do
      let(:run_attributes) { super().merge("result_count" => 4, "started_at" => 2.minutes.ago.iso8601) }

      it "shows an estimate" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("p", text: /About \d+ minutes? remaining/)
      end
    end

    context "when the run has been going for a while" do
      let(:run_attributes) { super().merge("started_at" => 10.minutes.ago.iso8601) }

      it "shows a reassuring note instead of going silent" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("p", text: "This run has been going for a while")
      end
    end

    context "when the run has finished" do
      let(:run_attributes) do
        super().merge(
          "status" => "completed", "result_count" => 10, "run_time_overrides" => { "max_rounds" => 3 },
          "effective_configuration" => { "max_rounds" => 3 },
          "gold_in_top1_count" => 6, "gold_in_top5_count" => 9, "total_latency_seconds" => 25.0,
          "max_cost_result" => { "id" => "55", "source_type" => "atar", "source_id" => "600004365", "cost_usd" => "0.05", "latency_seconds" => "3.2" },
          "min_cost_result" => nil
        )
      end

      it "does not show a cancel button" do
        expect(Capybara.string(rendered_page.body)).not_to have_button("Cancel run")
      end

      it "shows a back link, since there's nothing left to watch" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("a.govuk-back-link", text: "Back to experiments")
      end

      it "shows the full summary and the configuration breakdown, tagged by source" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("dd", text: "10")
        expect(page).to have_css("td", text: "Max rounds")
        expect(page).to have_css("td", text: "Overridden for this run")
      end

      it "shows accuracy and average latency, computed from the run's own counts" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("dd", text: "60%")
        expect(page).to have_css("dd", text: "90%")
        expect(page).to have_css("dd", text: "2.5")
      end

      it "shows the costliest result with a link, and a plain dash when there is no cheapest one" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_link("600004365 ($0.05)", href: evaluation_run_result_path(run_id, "55"))
        expect(page).to have_css("dd", text: "-")
      end
    end

    context "when the run was cancelled" do
      let(:run_attributes) { super().merge("status" => "cancelled", "result_count" => 1) }

      it "shows a back link" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("a.govuk-back-link", text: "Back to experiments")
      end
    end

    context "when the run has failed to start" do
      let(:run_attributes) { super().merge("status" => "failed", "result_count" => 0, "error_summary" => "could not reach the evaluation service: connection refused") }

      it "shows the error_summary, not just the bare status" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("p", text: "could not reach the evaluation service: connection refused")
      end

      it "shows a back link" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("a.govuk-back-link", text: "Back to experiments")
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

      it "includes a back link in the replaced HTML — the page never reloads to pick up show.html.erb's own, so it must live in the polled partial" do
        html = JSON.parse(rendered_page.body)["html"]

        expect(Capybara.string(html)).to have_css("a.govuk-back-link", text: "Back to experiments")
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

  describe "GET #index" do
    let(:make_request) { get evaluation_runs_path }
    let(:run_attributes) { { "experiment_id" => 7, "status" => "completed", "gold_query_set_id" => 3, "result_count" => 10, "error_count" => 0, "created_at" => "2026-10-01T09:00:00Z" } }

    def paginated_response(rows, total_count: rows.length)
      {
        status: 200,
        headers: json_headers,
        body: {
          data: rows.map { |attributes| { type: "run", id: attributes["resource_id"], attributes: attributes.except("resource_id") } },
          meta: { pagination: { page: 1, per_page: 20, total_count: } },
        }.to_json,
      }
    end

    before do
      stub_api_request("/search/evaluation/runs")
        .and_return(paginated_response([run_attributes.merge("resource_id" => "9")]))
    end

    it { is_expected.to have_http_status :success }

    it "lists the runs with their status and progress" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h1", text: "Evaluation runs")
      expect(page).to have_link("Run #9", href: evaluation_run_path("9"))
      expect(page).to have_css("td", text: "completed")
      expect(page).to have_css("td", text: "10 of")
    end

    context "when filtering by status" do
      let(:make_request) { get evaluation_runs_path(status: "failed") }

      before { stub_api_request("/search/evaluation/runs").with(query: hash_including("status" => "failed")).and_return(paginated_response([])) }

      it { is_expected.to have_http_status :success }
    end

    context "when asking for the second page" do
      let(:make_request) { get evaluation_runs_path(page: 2) }

      before { stub_api_request("/search/evaluation/runs").with(query: hash_including("page" => "2")).and_return(paginated_response([run_attributes.merge("resource_id" => "10")], total_count: 21)) }

      it "requests that page from the backend, not an unbounded fetch" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_link("Run #10")
      end
    end

    context "when the backend cannot be reached" do
      before { stub_api_request("/search/evaluation/runs").and_return(status: 500, headers: json_headers, body: { error: "boom" }.to_json) }

      it "shows an empty list and a warning instead of an error page" do
        expect(rendered_page).to have_http_status(:success)
        expect(rendered_page.body).to include("Runs could not be loaded. Try again.")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations, RSpec/MultipleMemoizedHelpers
