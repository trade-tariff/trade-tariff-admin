# rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
RSpec.describe EvaluationResultsController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }
  let(:run_id) { "9" }
  let(:json_headers) { { "content-type" => "application/json; charset=utf-8" } }
  let(:result_attributes) do
    {
      "run_id" => 9,
      "source_type" => "atar",
      "source_id" => "600004365",
      "persona" => "emu_generic",
      "expected_code" => "6404199000",
      "final_code" => "6404199000",
      "final_rank" => 1,
      "gold_in_top1" => true,
      "gold_in_top5" => true,
      "cost_usd" => "0.0034",
      "latency_seconds" => "1.25",
      "error" => nil,
      "trace" => { "question_trace" => [
        { "round" => 1, "question" => "What material?", "options" => %w[Rubber Leather], "chosen" => "Rubber", "reasoning" => "oracle text says rubber sole", "attempts" => 1, "simulator_failed" => false, "request_id" => "22222222-2222-2222-2222-222222222222" },
      ] },
    }
  end

  def paginated_response(rows, total_count: rows.length)
    {
      status: 200,
      headers: json_headers,
      body: {
        data: rows.map { |attributes| { type: "result", id: attributes["resource_id"], attributes: attributes.except("resource_id") } },
        meta: { pagination: { page: 1, per_page: 20, total_count: } },
      }.to_json,
    }
  end

  describe "GET #index" do
    let(:make_request) { get evaluation_run_results_path(run_id) }

    before do
      stub_api_request("/search/evaluation/results").with(query: hash_including("run_id" => run_id)).and_return(paginated_response([result_attributes.merge("resource_id" => "55")]))
    end

    it { is_expected.to have_http_status :success }

    it "lists the results with pass/fail, cost and latency" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h1", text: "Results")
      expect(page).to have_link("600004365", href: evaluation_run_result_path(run_id, "55"))
      expect(page).to have_css("td", text: "Pass")
      expect(page).to have_css("td", text: "0.0034")
      expect(page).to have_css("td", text: "1.25")
    end

    context "when the source is a synthetic ATaR" do
      # A synthetic ATaR's source_id is its own small database id (see
      # Evaluation::GoldQuerySource, synthetic_atar.id.to_s) — a bare "8" with no type label
      # alongside it is indistinguishable from any other row with an equally short id, and
      # doesn't tell an operator what they're actually looking at or let them find the real
      # classification code at a glance.
      let(:result_attributes) { super().merge("source_type" => "synthetic_atar", "source_id" => "8") }

      before do
        stub_api_request("/search/evaluation/results").with(query: hash_including("run_id" => run_id)).and_return(paginated_response([result_attributes.merge("resource_id" => "55")]))
      end

      it "shows the source type alongside the id, not just the bare id" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_link("Synthetic ATaR 8", href: evaluation_run_result_path(run_id, "55"))
      end
    end

    context "when asking for the second page" do
      let(:make_request) { get evaluation_run_results_path(run_id, page: 2) }

      before { stub_api_request("/search/evaluation/results").with(query: hash_including("page" => "2")).and_return(paginated_response([result_attributes.merge("resource_id" => "56", "source_id" => "600099999")], total_count: 21)) }

      it "requests that page from the backend, not an unbounded fetch" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_link("600099999")
      end
    end

    context "when the backend cannot be reached" do
      before { stub_api_request("/search/evaluation/results").with(query: hash_including("run_id" => run_id)).and_return(status: 500, headers: json_headers, body: { error: "boom" }.to_json) }

      it "shows an empty list and a warning instead of an error page" do
        expect(rendered_page).to have_http_status(:success)
        expect(rendered_page.body).to include("Results could not be loaded. Try again.")
      end
    end
  end

  describe "GET #show" do
    let(:make_request) { get evaluation_run_result_path(run_id, "55") }

    before { stub_api_request("/search/evaluation/results/55").and_return(jsonapi_response("result", result_attributes.merge("resource_id" => "55"))) }

    it { is_expected.to have_http_status :success }

    it "shows the result and its trace, one row per round" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h1", text: "600004365")
      expect(page).to have_css("td", text: "What material?")
      expect(page).to have_css("td", text: "Rubber")
      expect(page).to have_css("details", text: "oracle text says rubber sole")
    end

    it "shows rank, accuracy, cost and latency, not just the bare outcome" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("dd", text: "1")
      expect(page).to have_css("dd", text: "Yes")
      expect(page).to have_css("dd", text: "0.0034")
      expect(page).to have_css("dd", text: "1.25")
    end

    context "when the source is a synthetic ATaR" do
      # Same gap as the index page — a synthetic ATaR's source_id is a bare database id (e.g.
      # "8"), not a real ATaR's long reference number. The h1 showing only that bare id gives an
      # operator no way to tell what they're looking at.
      let(:result_attributes) { super().merge("source_type" => "synthetic_atar", "source_id" => "8") }

      it "shows the source type in the heading, not just the bare id" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("h1", text: "Synthetic ATaR 8")
      end
    end

    context "when the result errored" do
      let(:result_attributes) { super().merge("final_code" => nil, "final_rank" => nil, "gold_in_top1" => false, "gold_in_top5" => false, "error" => "could not reach the search service: timeout") }

      it "shows the error, not just Fail with no explanation" do
        expect(rendered_page.body).to include("could not reach the search service: timeout")
      end
    end

    it "links each round to its own Search Diagnostics page, asking for the full 7-day lookback" do
      # Without an explicit lookback_hours, SearchDiagnosticsController#show passes an empty
      # filter through to the backend, which defaults to RequestLogLookup::DEFAULT_LOOKBACK_HOURS
      # (72 hours) — far short of the 7 days (168 hours, SearchDiagnostic::MAX_LOOKBACK_HOURS) the
      # spec promises. An eval run being investigated via this drill-in page is routinely more
      # than 3 days old, so the link must ask for the full window explicitly.
      page = Capybara.string(rendered_page.body)

      expect(page).to have_link("View search internals", href: search_diagnostic_path("22222222-2222-2222-2222-222222222222", lookback_hours: SearchDiagnostic::MAX_LOOKBACK_HOURS))
    end

    context "when a round has no request_id (recorded before this link existed)" do
      let(:result_attributes) { super().deep_merge("trace" => { "question_trace" => [{ "round" => 1 }] }) }

      it "shows a dash instead of a dead link" do
        page = Capybara.string(rendered_page.body)

        expect(page).not_to have_link("View search internals")
        expect(page).to have_css("td", text: "-")
      end
    end

    context "when the result has no trace" do
      let(:result_attributes) { super().merge("trace" => {}) }

      it "explains why, instead of leaving an operator wondering if something's broken" do
        # The two real causes read very differently to an operator: a search that converged on
        # its first round never had a question to record (expected, not a gap); a result from
        # before this trace-recording feature shipped (AI-1068 Task 3) genuinely has none. A bare
        # "No Q&A trace recorded" either way reads as a bug report either way to someone who just
        # watched a different result show a full trace moments earlier. have_css, not a raw body
        # substring check, since the view's own text wraps across lines in the rendered HTML.
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("p", text: "No clarifying questions were recorded for this result")
        expect(page).to have_css("p", text: "converged on the first search")
      end
    end

    context "when the backend cannot be reached" do
      before { stub_api_request("/search/evaluation/results/55").to_raise(Faraday::ConnectionFailed) }

      it "redirects to the results list with a warning instead of an error page — Review Focus item 5, same rule as every other screen in this slice" do
        expect(rendered_page).to redirect_to(evaluation_run_results_path(run_id))

        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Result could not be loaded. Try again.")
      end
    end

    context "when a round's simulator failed" do
      let(:result_attributes) do
        super().deep_merge("trace" => { "question_trace" => [{ "round" => 2, "simulator_failed" => true, "question" => "What closure?", "chosen" => nil }] })
      end

      it "shows that round as failed" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css("td", text: "Simulator failed")
      end
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength
