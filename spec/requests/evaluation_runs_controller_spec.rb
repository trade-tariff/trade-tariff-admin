RSpec.describe EvaluationRunsController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator, uid: "user-123") }

  def experiment_attributes
    { "name" => "Baseline", "configuration_overrides" => {}, "gold_query_set_id" => 3 }
  end

  def gold_query_set_attributes
    { "name" => "Set A", "atar_count" => 5, "synthetic_atar_count" => 0 }
  end

  def json_headers
    { "content-type" => "application/json; charset=utf-8" }
  end

  def configuration_response
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

  def page
    Capybara.string(rendered_page.body)
  end

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

    it "shows the launch heading" do
      expect(page).to have_css("h1", text: "Launch an evaluation")
    end

    it "offers the experiment choices" do
      expect(page).to have_select("Experiment", options: ["Choose an experiment", "Baseline"])
    end

    it "does not offer a gold query set select" do
      expect(page).not_to have_select("Gold query set")
    end

    it "offers the question model select" do
      expect(page).to have_select("Question model")
    end

    it "offers the max rounds field" do
      expect(page).to have_field("Max rounds")
    end

    it "offers the search non declarables fieldset" do
      expect(page).to have_css("fieldset", text: "Search non declarables")
    end

    it "offers the launch button" do
      expect(page).to have_button("Launch")
    end

    it "puts overrides in an accordion" do
      accordion = page.find(".govuk-accordion[data-module='govuk-accordion']")

      expect(accordion).to have_css(".govuk-accordion__section-button", text: "Overrides")
    end

    it "keeps the question model inside the accordion" do
      accordion = page.find(".govuk-accordion[data-module='govuk-accordion']")

      expect(accordion).to have_select("Question model")
    end

    it "keeps max rounds inside the accordion" do
      accordion = page.find(".govuk-accordion[data-module='govuk-accordion']")

      expect(accordion).to have_field("Max rounds")
    end

    it "embeds the gold query set name in the preview data" do
      experiments_data = JSON.parse(page.find("form")["data-run-preview-experiments-value"])

      expect(experiments_data.dig("7", "gold_query_set_name")).to eq("Set A")
    end

    it "embeds the gold query set item count in the preview data" do
      experiments_data = JSON.parse(page.find("form")["data-run-preview-experiments-value"])

      expect(experiments_data.dig("7", "gold_query_set_item_count")).to eq(5)
    end

    it "explains the question model override" do
      expect(page).to have_css(".govuk-hint", text: "The AI model used to ask clarifying questions.")
    end

    it "explains the search non declarables override" do
      expect(page).to have_css(".govuk-hint", text: "Include non-declarable codes in the results.")
    end

    it "says a number field can be left blank" do
      expect(page).to have_css(".govuk-hint", text: "Leave blank to use the default.")
    end

    it "renders three boolean override radios" do
      radios = page.all("input[type='radio'][data-override-key='search_non_declarables']")

      expect(radios.size).to eq(3)
    end

    it "puts the preview target on each boolean radio" do
      radios = page.all("input[type='radio'][data-override-key='search_non_declarables']")

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

      it "redirects to the experiment list" do
        expect(rendered_page).to redirect_to(evaluation_experiments_path)
      end

      it "warns that the launch form could not be loaded" do
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

      it "shows the error" do
        expect(page).to have_css(".govuk-error-summary", text: "must be between 1 and 20")
      end

      it "keeps the same idempotency key" do
        expect(page).to have_css("input[name='evaluation_run[idempotency_key]'][value='key-abc']", visible: false)
      end

      it "keeps the experiment selection" do
        expect(page).to have_select("Experiment", selected: "Baseline")
      end

      it "keeps the typed max rounds" do
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

      it "keeps the same idempotency key" do
        expect(page).to have_css("input[name='evaluation_run[idempotency_key]'][value='key-abc']", visible: false)
      end

      it "keeps the experiment selection" do
        expect(page).to have_select("Experiment", selected: "Baseline")
      end

      it "keeps the typed max rounds" do
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

      it "returns unprocessable content" do
        expect(rendered_page).to have_http_status(:unprocessable_content)
      end

      it "does not call the backend" do
        rendered_page

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

    context "when the run has a generated label (AI-1437)" do
      let(:run_attributes) { super().merge("label" => "vector based retrieval") }

      it "appends the label to the heading" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("h1", text: "Baseline — Run ID: 9 — vector based retrieval")
      end
    end

    it "shows the live count" do
      expect(page).to have_css("p", text: "4 of 30")
    end

    it "shows a cancel button while the run is in progress" do
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
          "max_cost_result" => { "id" => "55", "source_type" => "atar", "source_id" => "600004365", "expected_code" => "6404199000", "cost_usd" => "0.05", "latency_seconds" => "3.2" },
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

      it "shows the result count" do
        expect(page).to have_css("dd", text: "10")
      end

      it "shows max rounds in the configuration" do
        expect(page).to have_css("td", text: "Max rounds")
      end

      it "tags max rounds as overridden for this run" do
        expect(page).to have_css("td", text: "Overridden for this run")
      end

      it "shows top-1 accuracy" do
        expect(page).to have_css("dd", text: "60%")
      end

      it "shows top-5 accuracy" do
        expect(page).to have_css("dd", text: "90%")
      end

      it "shows average latency" do
        expect(page).to have_css("dd", text: "2.5")
      end

      it "explains top-1 accuracy" do
        expect(page).to have_css("dd .govuk-hint", text: "top result")
      end

      it "explains the cost" do
        expect(page).to have_css("dd .govuk-hint", text: "clarifying question")
      end

      it "explains latency" do
        expect(page).to have_css("dd .govuk-hint", text: "simulating the trader")
      end

      it "links the costliest result" do
        expect(page).to have_link("ATaR 600004365 (6404199000, $0.05)", href: evaluation_run_result_path(run_id, "55"))
      end

      it "shows a dash when there is no cheapest result" do
        expect(page).to have_css("dd", text: "-")
      end
    end

    context "when the run has finished with a persona breakdown" do
      let(:run_attributes) do
        super().merge(
          "status" => "completed",
          "persona_breakdown" => {
            "emu_generic" => { "result_count" => 2, "gold_in_top1_count" => 1, "gold_in_top5_count" => 2, "total_cost_usd" => 0.03, "total_latency_seconds" => 5.0 },
            "emu_specific" => { "result_count" => 1, "gold_in_top1_count" => 1, "gold_in_top5_count" => 1, "total_cost_usd" => 0.05, "total_latency_seconds" => 1.0 },
          },
        )
      end

      it "shows the generic search persona" do
        expect(page).to have_css("td", text: "Generic search")
      end

      it "shows the specific search persona" do
        expect(page).to have_css("td", text: "Specific search")
      end

      it "shows that persona's top-1 accuracy" do
        expect(page).to have_css("td", text: "50%")
      end

      it "shows that persona's average latency" do
        expect(page).to have_css("td", text: "2.5")
      end
    end

    context "when the run has finished with some results priced against an untracked model" do
      let(:run_attributes) { super().merge("status" => "completed", "unpriced_result_count" => 3) }

      it "warns that the total cost may be understated, instead of showing it as if it were complete" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("p", text: "3 results have unknown pricing")
      end
    end

    context "when the run has finished with a setting from the experiment's own default, not a run-time override" do
      let(:run_attributes) do
        super().merge(
          "status" => "completed", "effective_configuration" => { "max_rounds" => 3, "rrf_k" => 40 },
          "run_time_overrides" => { "max_rounds" => 3 }
        )
      end
      let(:experiment_attributes) { super().merge("configuration_overrides" => { "rrf_k" => 40 }) }

      it "shows the rrf k setting" do
        expect(page).to have_css("td", text: "Rrf k")
      end

      it "tags it as the experiment default" do
        expect(page).to have_css("td", text: "From the experiment's own default")
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

    context "with the polling JSON response, when the run has finished with a setting from the experiment's own default" do
      let(:make_request) { get evaluation_run_path(run_id, format: :json) }
      let(:run_attributes) { super().merge("status" => "completed", "effective_configuration" => { "rrf_k" => 40 }) }
      let(:experiment_attributes) { super().merge("configuration_overrides" => { "rrf_k" => 40 }) }

      it "fetches the experiment for this response too, so the Configuration table tags sources correctly" do
        # Guards the ledger's Task 5 ruling: #show fetches @experiment unconditionally for
        # HTML, but only `unless @run.generating?` for JSON — if that guard were ever widened
        # to skip the fetch here too, every experiment-sourced setting would silently mis-tag
        # as "Baseline, not overridden" instead of raising anything an operator would notice.
        html = JSON.parse(rendered_page.body)["html"]

        expect(Capybara.string(html)).to have_css("td", text: "From the experiment's own default")
      end
    end

    context "when the backend cannot be reached" do
      before { stub_api_request("/search/evaluation/runs/#{run_id}").to_raise(Faraday::ConnectionFailed) }

      it "redirects to the experiment list" do
        expect(rendered_page).to redirect_to(evaluation_experiments_path)
      end

      it "warns that the launch form could not be loaded" do
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

      it "redirects to the run" do
        expect(rendered_page).to redirect_to(evaluation_run_path(run_id))
      end

      it "does not send a cancel request" do
        rendered_page

        expect(a_request(:patch, %r{/runs/#{run_id}})).not_to have_been_made
      end
    end
  end

  describe "GET #index" do
    let(:make_request) { get evaluation_runs_path }
    let(:run_attributes) do
      {
        "experiment_id" => 7,
        "experiment_name" => "Baseline",
        "status" => "completed",
        "gold_query_set_id" => 3,
        "result_count" => 10,
        "error_count" => 2,
        "total_cost_usd" => "0.0421",
        "started_at" => "2026-10-01T09:00:00Z",
        "completed_at" => "2026-10-01T09:05:00Z",
        "created_at" => "2026-10-01T09:00:00Z",
      }
    end

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
      stub_api_request("/search/evaluation/experiments").with(query: hash_including("per_page" => "200"))
        .and_return(
          status: 200,
          headers: json_headers,
          body: {
            data: [{ type: "experiment", id: "7", attributes: experiment_attributes }],
            meta: { pagination: { page: 1, per_page: 200, total_count: 1 } },
          }.to_json,
        )
    end

    it { is_expected.to have_http_status :success }

    it "shows the heading" do
      expect(page).to have_css("h1", text: "Evaluation runs")
    end

    it "links to the run" do
      expect(page).to have_link("Run #9", href: evaluation_run_path("9"))
    end

    it "shows the experiment name" do
      expect(page).to have_css("td", text: "Baseline")
    end

    it "shows the status" do
      expect(page).to have_css("td", text: "completed")
    end

    # result_count already includes errored results (reconcile_aggregates! counts every
    # ingested result, successes and failures alike). "10 done, 2 failed" reads correctly.
    # The old "result_count of (error_count + result_count)" text would have doubled every
    # failure into the denominator, showing "10 of 12" for a run that reported on 10.
    it "shows progress without double-counting failures" do
      expect(page).to have_css("td", text: "10 done, 2 failed")
    end

    it "shows the cost" do
      expect(page).to have_css("td", text: "0.0421")
    end

    context "when a run has a generated label (AI-1437)" do
      before do
        stub_api_request("/search/evaluation/runs")
          .and_return(paginated_response([run_attributes.merge("resource_id" => "9", "label" => "vector based retrieval")]))
      end

      it "shows the label next to the run's id" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_link("Run #9 — vector based retrieval", href: evaluation_run_path("9"))
      end
    end

    it "offers a status filter" do
      expect(page).to have_select("Status", options: ["All", "Queued", "Running", "Completed", "Partially failed", "Failed", "Cancelled"])
    end

    it "offers an experiment filter" do
      expect(page).to have_select("Experiment", options: ["All experiments", "Baseline"])
    end

    it "offers a from field" do
      expect(page).to have_field("From")
    end

    it "offers a to field" do
      expect(page).to have_field("To")
    end

    context "when filtering by status" do
      let(:make_request) { get evaluation_runs_path(status: "failed") }

      before { stub_api_request("/search/evaluation/runs").with(query: hash_including("status" => "failed")).and_return(paginated_response([])) }

      it { is_expected.to have_http_status :success }

      it "pre-selects the chosen status in the filter form" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_select("Status", selected: "Failed")
      end
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

      it "returns success" do
        expect(rendered_page).to have_http_status(:success)
      end

      it "warns that runs could not be loaded" do
        expect(rendered_page.body).to include("Runs could not be loaded. Try again.")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end

    context "when filtering by a specific experiment" do
      let(:make_request) { get evaluation_runs_path(experiment_id: "7") }

      before { stub_api_request("/search/evaluation/runs").with(query: hash_including("experiment_id" => "7")).and_return(paginated_response([run_attributes.merge("resource_id" => "9")])) }

      it "offers a checkbox shared by compare and delete" do
        expect(page).to have_field("run_ids[]", type: "checkbox")
      end

      it "offers the compare button" do
        expect(page).to have_button("Compare selected runs")
      end

      it "offers the delete button" do
        expect(page).to have_button("Delete selected runs")
      end
    end

    it "does not offer a checkbox for mixed experiments" do
      expect(page).not_to have_field("run_ids[]", type: "checkbox")
    end

    it "does not offer the compare button for mixed experiments" do
      expect(page).not_to have_button("Compare selected runs")
    end

    it "does not offer the delete button for mixed experiments" do
      expect(page).not_to have_button("Delete selected runs")
    end

    # Checkbox visibility depends only on whether a run is still in progress (AI-1441) -- not on
    # comparable_run?/fully_scored? at all, which only matters once a selection is actually
    # submitted to Compare (tested separately in the GET #compare section below). A failed or
    # cancelled run is exactly the clutter an operator most wants to delete, so it gets a
    # checkbox now; a queued/running run does not, since it can't be deleted until cancelled.
    context "when filtering by a specific experiment, and a run is queued or running" do
      let(:make_request) { get evaluation_runs_path(experiment_id: "7") }
      let(:run_attributes) { super().merge("status" => "running") }

      before { stub_api_request("/search/evaluation/runs").with(query: hash_including("experiment_id" => "7")).and_return(paginated_response([run_attributes.merge("resource_id" => "9")])) }

      it "does not offer a checkbox for a run that's still in progress" do
        page = Capybara.string(rendered_page.body)

        expect(page).not_to have_field("run_ids[]", type: "checkbox")
      end
    end

    %w[failed cancelled partially_failed].each do |status|
      context "when filtering by a specific experiment, and a run is #{status}" do
        let(:make_request) { get evaluation_runs_path(experiment_id: "7") }
        let(:run_attributes) { super().merge("status" => status) }

        before { stub_api_request("/search/evaluation/runs").with(query: hash_including("experiment_id" => "7")).and_return(paginated_response([run_attributes.merge("resource_id" => "9")])) }

        it "offers a checkbox, even though this status can't be compared -- it can still be deleted" do
          page = Capybara.string(rendered_page.body)

          expect(page).to have_field("run_ids[]", type: "checkbox")
        end
      end
    end
  end

  describe "GET #compare" do
    let(:make_request) { get compare_evaluation_runs_path(run_ids: %w[9 10], experiment_id: "7") }
    let(:run_a_attributes) do
      {
        "experiment_id" => 7,
        "experiment_name" => "Baseline",
        "status" => "completed",
        "result_count" => 10,
        "gold_in_top1_count" => 6,
        "gold_in_top5_count" => 9,
        "total_cost_usd" => "0.0500",
        "total_latency_seconds" => 25.0,
        "started_at" => "2026-10-01T09:00:00Z",
      }
    end
    let(:run_b_attributes) do
      {
        "experiment_id" => 7,
        "experiment_name" => "Baseline",
        "status" => "completed",
        "gold_query_set_id" => 3,
        "result_count" => 10,
        "gold_in_top1_count" => 8,
        "gold_in_top5_count" => 10,
        "total_cost_usd" => "0.0800",
        "total_latency_seconds" => 40.0,
        "started_at" => "2026-10-01T10:00:00Z",
      }
    end

    before do
      stub_api_request("/search/evaluation/runs/9").and_return(jsonapi_response("run", run_a_attributes.merge("resource_id" => "9")))
      stub_api_request("/search/evaluation/runs/10").and_return(jsonapi_response("run", run_b_attributes.merge("resource_id" => "10")))
    end

    it { is_expected.to have_http_status :success }

    it "shows the first run" do
      expect(page).to have_css("th", text: "Run #9")
    end

    it "shows the second run" do
      expect(page).to have_css("th", text: "Run #10")
    end

    it "shows the top 1 accuracy label" do
      expect(page).to have_css("td", text: "Top 1 accuracy")
    end

    it "shows the first run's top 1 accuracy" do
      expect(page).to have_css("td", text: "60%")
    end

    it "shows the second run's top 1 accuracy" do
      expect(page).to have_css("td", text: "80%")
    end

    context "when a compared run has a generated label (AI-1437)" do
      let(:run_b_attributes) { super().merge("label" => "vector based retrieval") }

      it "shows the label on that run's column header, not just its bare id" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("th", text: "Run #10 — vector based retrieval")
      end
    end

    context "when the two runs were started in the opposite order" do
      let(:make_request) { get compare_evaluation_runs_path(run_ids: %w[10 9], experiment_id: "7") }

      it "still shows the earlier-started run first, so the baseline is always on the left" do
        page = Capybara.string(rendered_page.body)

        headers = page.all("th").map(&:text)
        expect(headers.index { |text| text.include?("Run #9") }).to be < headers.index { |text| text.include?("Run #10") }
      end
    end

    context "when fewer than two runs are selected" do
      let(:make_request) { get compare_evaluation_runs_path(run_ids: %w[9], experiment_id: "7") }

      it "redirects to the filtered run list" do
        expect(rendered_page).to redirect_to(evaluation_runs_path(experiment_id: "7"))
      end

      it "explains that exactly two completed or partially failed runs are required" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("Select exactly two completed or partially failed runs from the same experiment to compare.")
      end
    end

    context "when more than two runs are selected" do
      let(:make_request) { get compare_evaluation_runs_path(run_ids: %w[9 10 11], experiment_id: "7") }

      before { stub_api_request("/search/evaluation/runs/11").and_return(jsonapi_response("run", run_a_attributes.merge("resource_id" => "11"))) }

      it "bounces back with the same explanation" do
        expect(rendered_page).to redirect_to(evaluation_runs_path(experiment_id: "7"))
      end
    end

    # Not "completed" covers a run still in flight and one that finished without completing
    # cleanly -- the latter matters because a cancelled-while-queued run has no started_at at
    # all, and the sort below would raise comparing nil with a string if it were ever reached
    # (AI-1427 review feedback). partially_failed is covered separately below (AI-1431), since
    # whether it's comparable depends on more than the status.
    %w[running failed cancelled].each do |status|
      context "when one of the selected runs is #{status}, not completed" do
        before { stub_api_request("/search/evaluation/runs/10").and_return(jsonapi_response("run", run_b_attributes.merge("status" => status, "resource_id" => "10"))) }

        it "bounces back rather than comparing a run that hasn't completed" do
          expect(rendered_page).to redirect_to(evaluation_runs_path(experiment_id: "7"))
        end
      end
    end

    # The widened delete checkbox (AI-1441) makes this reachable through the UI for the first
    # time -- a failed/cancelled run never had a checkbox at all before, so selecting two of
    # them for Compare was previously only possible via a hand-edited URL.
    context "when both selected runs are failed, not just one" do
      before { stub_api_request("/search/evaluation/runs/10").and_return(jsonapi_response("run", run_b_attributes.merge("status" => "failed", "resource_id" => "10"))) }

      let(:run_a_attributes) { super().merge("status" => "failed") }

      it "redirects when both selected runs failed" do
        expect(rendered_page).to redirect_to(evaluation_runs_path(experiment_id: "7"))
      end

      it "explains that only completed or partially failed runs can be compared" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("Select exactly two completed or partially failed runs from the same experiment to compare.")
      end
    end

    # partially_failed covers two different situations (AI-1431): every gold query still got a
    # result and only an individual Q&A session errored along the way (result_count matches the
    # run's own intended_result_count, snapshotted once at launch -- AI-1435), or the run was cut
    # short and the rest were never attempted (result_count falls short). Only the first is safe
    # to compare.
    context "when one of the selected runs is partially_failed but every gold query still got a result" do
      before { stub_api_request("/search/evaluation/runs/10").and_return(jsonapi_response("run", run_b_attributes.merge("status" => "partially_failed", "intended_result_count" => 10, "resource_id" => "10"))) }

      it "returns success" do
        expect(rendered_page).to have_http_status(:success)
      end

      it "shows the second run" do
        expect(page).to have_css("th", text: "Run #10")
      end

      it "flags the partially failed run" do
        expect(page.find("th", text: "Run #10")).to have_css("span.govuk-tag", text: "Partially failed")
      end
    end

    context "when one of the selected runs is partially_failed because it was cut short partway through" do
      before { stub_api_request("/search/evaluation/runs/10").and_return(jsonapi_response("run", run_b_attributes.merge("status" => "partially_failed", "result_count" => 4, "intended_result_count" => 10, "resource_id" => "10"))) }

      it "bounces back rather than comparing a run that was cut short" do
        expect(rendered_page).to redirect_to(evaluation_runs_path(experiment_id: "7"))
      end
    end

    # A run started before this field existed has no intended_result_count at all (never
    # backfilled -- AI-1435). Treated as not comparable, the same safe default as any other
    # partially_failed run this can't positively confirm was fully scored.
    context "when one of the selected runs is partially_failed and predates intended_result_count" do
      before { stub_api_request("/search/evaluation/runs/10").and_return(jsonapi_response("run", run_b_attributes.merge("status" => "partially_failed", "intended_result_count" => nil, "resource_id" => "10"))) }

      it "bounces back rather than comparing a run it can't confirm was fully scored" do
        expect(rendered_page).to redirect_to(evaluation_runs_path(experiment_id: "7"))
      end
    end

    context "when one of the selected runs was cancelled before it ever started running" do
      before { stub_api_request("/search/evaluation/runs/10").and_return(jsonapi_response("run", run_b_attributes.merge("status" => "cancelled", "started_at" => nil, "resource_id" => "10"))) }

      it "bounces back instead of raising when there's no started_at to sort by" do
        expect(rendered_page).to redirect_to(evaluation_runs_path(experiment_id: "7"))
      end
    end

    context "when the backend can't be reached while loading a selected run" do
      before { stub_api_request("/search/evaluation/runs/10").to_raise(Faraday::ConnectionFailed) }

      it "redirects to the experiment list" do
        expect(rendered_page).to redirect_to(evaluation_experiments_path)
      end

      it "warns that the launch form could not be loaded" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("The launch form could not be loaded. Try again.")
      end
    end

    context "when the selected runs belong to different experiments" do
      before { stub_api_request("/search/evaluation/runs/10").and_return(jsonapi_response("run", run_b_attributes.merge("experiment_id" => 99, "resource_id" => "10"))) }

      it "returns found" do
        expect(rendered_page).to have_http_status(:found)
      end

      it "explains that the runs must belong to the same experiment" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("Select exactly two completed or partially failed runs from the same experiment to compare.")
      end
    end

    context "when a selected run does not exist" do
      before { stub_api_request("/search/evaluation/runs/10").to_raise(Faraday::ResourceNotFound) }

      it "bounces back with the same explanation, rather than a 404" do
        expect(rendered_page).to redirect_to(evaluation_runs_path(experiment_id: "7"))
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "GET #confirm_bulk_destroy" do
    let(:make_request) { get confirm_bulk_destroy_evaluation_runs_path(run_ids: %w[9 10], experiment_id: "7") }

    it "asks for confirmation" do
      expect(page).to have_css("h1", text: "Are you sure you want to delete these runs?")
    end

    it "warns how many runs will be lost" do
      expect(page).to have_css(".govuk-warning-text", text: "2 runs")
    end

    it "lists the first selected run" do
      expect(page).to have_content("Run #9")
    end

    it "lists the second selected run" do
      expect(page).to have_content("Run #10")
    end

    it "offers the bulk delete button" do
      expect(page).to have_button("Delete 2 runs")
    end

    context "when no runs are selected" do
      let(:make_request) { get confirm_bulk_destroy_evaluation_runs_path }

      it "redirects instead of showing an empty confirmation" do
        expect(rendered_page).to redirect_to(evaluation_runs_path)
      end

      it "explains that a selection is required" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("Select at least one run to delete.")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "DELETE #bulk_destroy" do
    let(:make_request) { delete bulk_destroy_evaluation_runs_path, params: { run_ids: %w[9 10], experiment_id: "7" } }

    before { stub_api_request("/search/evaluation/runs/bulk_destroy", :delete).with(query: hash_including({})).and_return(status: 204, headers: json_headers, body: nil) }

    it { is_expected.to redirect_to(evaluation_runs_path(experiment_id: "7")) }

    it "confirms the deletion" do
      rendered_page

      expect(session.dig("flash", "flashes", "notice")).to eq("2 runs deleted.")
    end

    it "sends every selected id in one request" do
      rendered_page

      expect(WebMock).to(have_requested(:delete, %r{/search/evaluation/runs/bulk_destroy}).with do |request|
        query = Rack::Utils.parse_nested_query(request.uri.query)
        query["run_ids"].sort == %w[10 9]
      end)
    end

    context "when one of the selected runs is queued or running" do
      let(:detail) { "One or more selected runs are queued or running. Wait for them to finish, or cancel them, then try again." }

      before do
        stub_api_request("/search/evaluation/runs/bulk_destroy", :delete).with(query: hash_including({})).and_return(
          status: 409, headers: json_headers, body: { errors: [{ status: "409", title: "Run is in use", detail: }] }.to_json,
        )
      end

      it { is_expected.to redirect_to(evaluation_runs_path(experiment_id: "7")) }

      it "explains why it was refused, using the backend's own wording" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq(detail)
      end
    end

    context "when the backend refuses without saying why" do
      before { stub_api_request("/search/evaluation/runs/bulk_destroy", :delete).with(query: hash_including({})).and_return(status: 409, headers: json_headers, body: "") }

      it "falls back to the same wording" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq(
          "One or more selected runs are queued or running. Wait for them to finish, or cancel them, then try again.",
        )
      end
    end

    context "when the backend cannot be reached" do
      before { stub_api_request("/search/evaluation/runs/bulk_destroy", :delete).with(query: hash_including({})).and_return(status: 500, headers: json_headers, body: { error: "boom" }.to_json) }

      it "redirects instead of showing an error page" do
        expect(rendered_page).to redirect_to(evaluation_runs_path(experiment_id: "7"))
      end

      it "warns that the runs could not be deleted" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("Runs could not be deleted. Try again.")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end
end
