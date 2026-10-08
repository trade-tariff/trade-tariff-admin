RSpec.describe EvaluationRun do
  describe ".launch!" do
    let(:response_attributes) do
      {
        "experiment_id" => 7,
        "status" => "queued",
        "gold_query_set_id" => 3,
        "effective_configuration" => { "question_model" => "gpt-5.4" },
        "result_count" => 0,
      }
    end

    context "when the backend accepts it" do
      before do
        stub_api_request("/search/evaluation/runs", :post)
          .with { |request|
            body = JSON.parse(request.body)
            attributes = body.dig("data", "attributes")
            request.headers["Idempotency-Key"] == "key-123" &&
              request.headers["Content-Type"]&.start_with?("application/json") &&
              attributes == { "experiment_id" => "7", "triggered_by" => "user-123", "configuration_overrides" => { "max_rounds" => 3 } }
          }
          .and_return(jsonapi_response("run", response_attributes.merge("resource_id" => "9")))
      end

      it "returns the created run" do
        run = described_class.launch!(
          experiment_id: "7", triggered_by: "user-123",
          run_time_overrides: { max_rounds: 3 }, idempotency_key: "key-123"
        )

        expect(run).to have_attributes(resource_id: "9", status: "queued")
      end
    end

    context "when the backend rejects it" do
      before do
        stub_api_request("/search/evaluation/runs", :post)
          .and_return(api_error_response(experiment_id: "does not exist"))
      end

      it "returns a run carrying the errors, not an exception" do
        run = described_class.launch!(
          experiment_id: "999", triggered_by: "user-123",
          run_time_overrides: {}, idempotency_key: "key-123"
        )

        expect(run.errors[:experiment_id]).to include("Experiment does not exist")
      end
    end
  end
end
