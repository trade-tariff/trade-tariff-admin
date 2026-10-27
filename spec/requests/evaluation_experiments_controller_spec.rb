RSpec.describe EvaluationExperimentsController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }
  let(:experiment_id) { "7" }
  let(:experiment_attributes) do
    {
      "name" => "Baseline",
      "description" => "No overrides",
      "enabled" => true,
      "configuration_overrides" => {},
      "default_scope" => {},
      "gold_query_set_id" => 3,
      "created_by" => "user-123",
      "created_at" => "2026-10-01T10:00:00Z",
    }
  end

  def json_headers
    { "content-type" => "application/json; charset=utf-8" }
  end

  def experiment_response
    jsonapi_response("experiment", experiment_attributes.merge("resource_id" => experiment_id))
  end

  def page
    Capybara.string(rendered_page.body)
  end

  def paginated_response(rows, total_count: rows.length)
    {
      status: 200,
      headers: json_headers,
      body: {
        data: rows.map { |attributes| { type: "experiment", id: attributes["resource_id"], attributes: attributes.except("resource_id") } },
        meta: { pagination: { page: 1, per_page: 20, total_count: } },
      }.to_json,
    }
  end

  describe "GET #index" do
    let(:make_request) { get evaluation_experiments_path }

    before do
      create(:user, uid: "user-123", name: "Alex Example")
      stub_api_request("/search/evaluation/experiments")
        .and_return(paginated_response([experiment_attributes.merge("resource_id" => experiment_id)]))
    end

    it { is_expected.to have_http_status :success }

    context "when experiments use different sets" do
      before do
        stub_api_request("/search/evaluation/experiments").and_return(
          paginated_response(
            [
              experiment_attributes.merge("resource_id" => "7", "name" => "On gold", "source_type" => "gold_query_set", "source_name" => "Baseline GQS", "gold_query_set_id" => 3),
              experiment_attributes.merge("resource_id" => "8", "name" => "On synthetic", "source_type" => "synthetic_input_set", "source_name" => "Baseline SIS", "gold_query_set_id" => nil, "synthetic_input_set_id" => 9),
              experiment_attributes.merge("resource_id" => "10", "name" => "On nothing", "source_type" => nil, "source_name" => nil, "gold_query_set_id" => nil),
            ],
          ),
        )
      end

      it "has a Source column" do
        expect(page).to have_css("th", text: "Source")
      end

      it "links a gold query set experiment to its set" do
        expect(page).to have_link("Baseline GQS", href: evaluation_gold_query_set_path(3))
      end

      it "links a synthetic input set experiment to its set" do
        expect(page).to have_link("Baseline SIS", href: evaluation_synthetic_input_set_path(9))
      end

      it "says which kind of set each experiment uses", :aggregate_failures do
        expect(page).to have_css("td", text: "Gold query set")
        expect(page).to have_css("td", text: "Synthetic input set")
      end

      it "says when an experiment has not chosen a set yet" do
        expect(page).to have_css("td", text: "None chosen")
      end
    end

    context "when the XI service is selected" do
      before { allow(TradeTariffAdmin::ServiceChooser).to receive(:service_choice).and_return "xi" }

      it "is not reachable, even by going straight to the address" do
        expect(rendered_page).to have_http_status :not_found
      end
    end

    it "shows the heading" do
      expect(page).to have_css("h1", text: "Evaluation experiments")
    end

    it "links to the experiment" do
      expect(page).to have_link("Baseline")
    end

    it "shows the creator" do
      expect(page).to have_css("td", text: "Alex Example")
    end

    it "links to a new experiment" do
      expect(page).to have_link("New experiment", href: new_evaluation_experiment_path)
    end

    it "marks Evaluations as the current evaluation tab" do
      expect(page).to have_css("nav.app-sub-navigation[aria-label='Evaluation'] a[aria-current='page']", text: "Evaluations")
    end

    it "links to that experiment's runs" do
      expect(page).to have_link("View runs", href: evaluation_runs_path(experiment_id: experiment_id))
    end

    # AI-1429: the only way into the runs list from this page should be scoped to one experiment
    # at a time (each row's own "View runs" link, asserted above) -- an unscoped "all runs" view
    # mixes every experiment's runs together and doesn't fit the run-comparison feature, which
    # only makes sense once you're already looking at one experiment's runs.
    it "offers no unscoped way to view every experiment's runs mixed together" do
      expect(page).not_to have_link("View all runs")
    end

    context "when there are no experiments" do
      before { stub_api_request("/search/evaluation/experiments").and_return(paginated_response([])) }

      it "says so" do
        expect(rendered_page.body).to include("No experiments yet.")
      end
    end

    context "when the backend cannot be reached" do
      before { stub_api_request("/search/evaluation/experiments").and_return(status: 500, headers: json_headers, body: { error: "boom" }.to_json) }

      it "returns success" do
        expect(rendered_page).to have_http_status(:success)
      end

      it "warns that experiments could not be loaded" do
        expect(rendered_page.body).to include("Experiments could not be loaded. Try again.")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "GET #new" do
    let(:make_request) { get new_evaluation_experiment_path }

    def synthetic_input_sets_response(rows = [])
      {
        status: 200,
        headers: json_headers,
        body: {
          data: rows.map { |attributes| { type: "synthetic_input_set", id: attributes["resource_id"], attributes: attributes.except("resource_id") } },
          meta: { pagination: { page: 1, per_page: 200, total_count: rows.length } },
        }.to_json,
      }
    end

    before do
      stub_api_request("/search/evaluation/synthetic_input_sets").with(query: hash_including("per_page" => "200")).and_return(synthetic_input_sets_response)
    end

    it "shows the heading" do
      expect(page).to have_css("h1", text: "New experiment")
    end

    it "shows the name field" do
      expect(page).to have_field("Name")
    end

    it "does not offer a gold query set choice" do
      expect(page).not_to have_field("Gold query set")
    end

    it "does not ask the backend for gold query sets" do
      rendered_page

      expect(a_request(:get, %r{/search/evaluation/gold_query_sets})).not_to have_been_made
    end

    it "offers the synthetic input set picker directly, with no radio choice to make first", :aggregate_failures do
      expect(page).to have_select("Synthetic input set")
      expect(page).not_to have_field(type: "radio")
    end

    it "still says the source cannot be changed once chosen" do
      expect(page).to have_text("This cannot be changed once chosen.")
    end

    context "when gold query sets are offered again" do
      before do
        allow(EvaluationGoldQuerySet).to receive(:entry_points_enabled?).and_return(true)
        stub_api_request("/search/evaluation/gold_query_sets").with(query: hash_including("per_page" => "200"))
          .and_return(paginated_response([{ "resource_id" => "3", "name" => "Baseline GQS" }]))
      end

      it "offers a gold query set radio choice" do
        expect(page).to have_field("Gold query set", type: "radio")
      end

      it "offers a synthetic input set radio choice" do
        expect(page).to have_field("Synthetic input set", type: "radio")
      end

      it "lists gold query sets in the gold query set picker" do
        expect(page).to have_select("Gold query set", with_options: ["Baseline GQS"])
      end
    end

    it "lists synthetic input sets in the synthetic input set picker" do
      stub_api_request("/search/evaluation/synthetic_input_sets").with(query: hash_including("per_page" => "200"))
                                                                  .and_return(synthetic_input_sets_response([{ "resource_id" => "9", "name" => "Baseline SIS" }]))

      expect(page).to have_select("Synthetic input set", with_options: ["Baseline SIS"])
    end

    it "shows the create button" do
      expect(page).to have_button("Create experiment")
    end
  end

  describe "POST #create" do
    let(:make_request) do
      post evaluation_experiments_path, params: {
        evaluation_experiment: { name: "Baseline", description: "No overrides", gold_query_set_id: "3" },
      }
    end

    context "when the backend accepts it" do
      before { stub_api_request("/search/evaluation/experiments", :post).and_return(experiment_response.merge(status: 201)) }

      it { is_expected.to redirect_to(evaluation_experiments_path) }

      it "confirms the creation" do
        rendered_page

        expect(session.dig("flash", "flashes", "notice")).to eq("Experiment created successfully.")
      end
    end

    context "when the backend rejects it" do
      before do
        stub_api_request("/search/evaluation/experiments", :post).and_return(api_error_response(name: "is already taken"))
        stub_api_request("/search/evaluation/gold_query_sets").with(query: hash_including("per_page" => "200")).and_return(paginated_response([]))
        stub_api_request("/search/evaluation/synthetic_input_sets").with(query: hash_including("per_page" => "200")).and_return(status: 200, headers: json_headers, body: { data: [], meta: { pagination: { page: 1, per_page: 200, total_count: 0 } } }.to_json)
      end

      it { is_expected.to have_http_status :unprocessable_content }

      it "shows the error" do
        expect(page).to have_css(".govuk-error-summary", text: "is already taken")
      end

      it "keeps the typed name" do
        expect(page).to have_field("Name", with: "Baseline")
      end
    end

    context "when a synthetic input set is chosen instead of a gold query set" do
      let(:make_request) do
        post evaluation_experiments_path, params: {
          evaluation_experiment: { name: "Baseline", source_type: "synthetic_input_set", synthetic_input_set_id: "9" },
        }
      end

      before do
        stub_api_request("/search/evaluation/experiments", :post)
          .with { |request|
            attributes = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            attributes["synthetic_input_set_id"] == "9" && attributes["gold_query_set_id"].nil?
          }
          .and_return(experiment_response.merge(status: 201))
      end

      it "sends synthetic_input_set_id, not gold_query_set_id" do
        expect(rendered_page).to redirect_to(evaluation_experiments_path)
      end
    end

    context "when the operator picked a gold query set, then switched to a synthetic input set without the hidden picker clearing itself" do
      # The conditional reveal only hides the inactive picker with CSS — its <select> keeps
      # whatever was chosen before the radio was switched, so a real request can submit both
      # ids. Only source_type says which pick is the operator's actual final choice.
      let(:make_request) do
        post evaluation_experiments_path, params: {
          evaluation_experiment: { name: "Baseline", source_type: "synthetic_input_set", gold_query_set_id: "3", synthetic_input_set_id: "9" },
        }
      end

      before do
        stub_api_request("/search/evaluation/experiments", :post)
          .with { |request|
            attributes = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            attributes["synthetic_input_set_id"] == "9" && attributes["gold_query_set_id"].nil?
          }
          .and_return(experiment_response.merge(status: 201))
      end

      it "sends only the synthetic_input_set_id, discarding the stale gold_query_set_id" do
        expect(rendered_page).to redirect_to(evaluation_experiments_path)
      end
    end

    context "when the operator picked a synthetic input set, then switched to a gold query set without the hidden picker clearing itself" do
      let(:make_request) do
        post evaluation_experiments_path, params: {
          evaluation_experiment: { name: "Baseline", source_type: "gold_query_set", gold_query_set_id: "3", synthetic_input_set_id: "9" },
        }
      end

      before do
        stub_api_request("/search/evaluation/experiments", :post)
          .with { |request|
            attributes = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            attributes["gold_query_set_id"] == "3" && attributes["synthetic_input_set_id"].nil?
          }
          .and_return(experiment_response.merge(status: 201))
      end

      it "sends only the gold_query_set_id, discarding the stale synthetic_input_set_id" do
        expect(rendered_page).to redirect_to(evaluation_experiments_path)
      end
    end

    context "when a rejected synthetic input set choice is redisplayed" do
      let(:make_request) do
        post evaluation_experiments_path, params: {
          evaluation_experiment: { name: "Baseline", source_type: "synthetic_input_set", synthetic_input_set_id: "9" },
        }
      end

      before do
        stub_api_request("/search/evaluation/experiments", :post).and_return(api_error_response(name: "is already taken"))
        stub_api_request("/search/evaluation/gold_query_sets").with(query: hash_including("per_page" => "200")).and_return(paginated_response([]))
        stub_api_request("/search/evaluation/synthetic_input_sets").with(query: hash_including("per_page" => "200"))
          .and_return(status: 200, headers: json_headers, body: { data: [{ type: "synthetic_input_set", id: "9", attributes: { name: "Baseline SIS" } }], meta: { pagination: { page: 1, per_page: 200, total_count: 1 } } }.to_json)
      end

      it "keeps the chosen synthetic input set selected" do
        expect(page).to have_select("Synthetic input set", selected: "Baseline SIS")
      end
    end

    context "when the backend cannot be reached" do
      before { stub_api_request("/search/evaluation/experiments", :post).and_return(status: 500, headers: json_headers, body: { error: "boom" }.to_json) }

      it "redirects to the experiments list" do
        expect(rendered_page).to redirect_to(evaluation_experiments_path)
      end

      it "warns that the experiment could not be loaded" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("The experiment could not be loaded. Try again.")
      end
    end
  end

  describe "GET #confirm_destroy" do
    let(:make_request) { get delete_evaluation_experiment_path(experiment_id) }

    before do
      stub_api_request("/search/evaluation/experiments/#{experiment_id}").and_return(experiment_response)
      stub_api_request("/search/evaluation/runs", :get).with(query: hash_including("experiment_id" => experiment_id)).and_return(paginated_response([], total_count: 2))
    end

    it "asks for confirmation" do
      expect(page).to have_css("h1", text: "Are you sure you want to delete this experiment?")
    end

    it "says how many runs will be lost" do
      expect(page).to have_css(".govuk-warning-text", text: "2 runs")
    end

    it "shows the delete button" do
      expect(page).to have_button("Delete experiment")
    end

    context "when the backend cannot be reached" do
      before { stub_api_request("/search/evaluation/runs", :get).with(query: hash_including("experiment_id" => experiment_id)).and_return(status: 500, headers: json_headers, body: { error: "boom" }.to_json) }

      it "redirects to the experiments list" do
        expect(rendered_page).to redirect_to(evaluation_experiments_path)
      end

      it "warns that the experiment could not be loaded" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("The experiment could not be loaded. Try again.")
      end
    end
  end

  describe "DELETE #destroy" do
    let(:make_request) { delete evaluation_experiment_path(experiment_id) }

    before do
      stub_api_request("/search/evaluation/experiments/#{experiment_id}").and_return(experiment_response)
      stub_api_request("/search/evaluation/experiments/#{experiment_id}", :delete).and_return(status: 204, headers: json_headers, body: nil)
    end

    it { is_expected.to redirect_to(evaluation_experiments_path) }

    it "confirms the deletion" do
      rendered_page

      expect(session.dig("flash", "flashes", "notice")).to eq("Experiment deleted successfully.")
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end

    context "when a run of the experiment is still queued or running" do
      let(:detail) { "This experiment cannot be deleted while one of its runs is queued or running. Wait for the run to finish, or cancel it, then try again." }

      before do
        stub_api_request("/search/evaluation/experiments/#{experiment_id}", :delete).and_return(
          status: 409, headers: json_headers, body: { errors: [{ status: "409", title: "Experiment is in use", detail: }] }.to_json,
        )
      end

      it { is_expected.to redirect_to(evaluation_experiments_path) }

      it "explains why it was refused, using the backend's own wording" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq(detail)
      end
    end

    context "when the backend refuses without saying why" do
      before do
        stub_api_request("/search/evaluation/experiments/#{experiment_id}", :delete).and_return(status: 409, headers: json_headers, body: "")
      end

      it "falls back to the same wording" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq(
          "This experiment cannot be deleted while one of its runs is queued or running. Wait for the run to finish, or cancel it, then try again.",
        )
      end
    end

    context "when the backend cannot be reached" do
      before { stub_api_request("/search/evaluation/experiments/#{experiment_id}", :delete).and_return(status: 500, headers: json_headers, body: { error: "boom" }.to_json) }

      it "redirects to the experiments list" do
        expect(rendered_page).to redirect_to(evaluation_experiments_path)
      end

      it "warns that the experiment could not be loaded" do
        rendered_page

        expect(session.dig("flash", "flashes", "alert")).to eq("The experiment could not be loaded. Try again.")
      end
    end
  end
end
