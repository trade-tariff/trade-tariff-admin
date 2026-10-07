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

  describe "#configuration_breakdown" do
    subject(:run) do
      described_class.new(
        "effective_configuration" => { "question_model" => "gpt-5.6", "max_rounds" => 3, "rrf_k" => 60 },
        "run_time_overrides" => { "question_model" => "gpt-5.6" },
      )
    end

    let(:experiment) { EvaluationExperiment.new(configuration_overrides: { "max_rounds" => 3 }) }

    # rubocop:disable RSpec/ExampleLength -- one coherent check of the whole breakdown shape; splitting
    # the three contain_exactly entries into separate examples would just repeat the same setup three
    # times for no gain in clarity.
    it "tags each key by where its value actually came from" do
      breakdown = run.configuration_breakdown(experiment)

      expect(breakdown).to contain_exactly(
        { name: "question_model", value: "gpt-5.6", source: "run" },
        { name: "max_rounds", value: 3, source: "experiment" },
        { name: "rrf_k", value: 60, source: "baseline" },
      )
    end
    # rubocop:enable RSpec/ExampleLength
  end

  describe "#top1_rate and #top5_rate" do
    it "is top1_rate as a percentage of finished results" do
      run = described_class.new("result_count" => 10, "gold_in_top1_count" => 3, "gold_in_top5_count" => 7)

      expect(run.top1_rate).to eq(30.0)
    end

    it "is top5_rate as a percentage of finished results" do
      run = described_class.new("result_count" => 10, "gold_in_top1_count" => 3, "gold_in_top5_count" => 7)

      expect(run.top5_rate).to eq(70.0)
    end

    it "is top1_rate nil, not a division error, when there are no results yet" do
      run = described_class.new("result_count" => 0, "gold_in_top1_count" => 0, "gold_in_top5_count" => 0)

      expect(run.top1_rate).to be_nil
    end

    it "is top5_rate nil, not a division error, when there are no results yet" do
      run = described_class.new("result_count" => 0, "gold_in_top1_count" => 0, "gold_in_top5_count" => 0)

      expect(run.top5_rate).to be_nil
    end
  end

  describe "#average_latency_seconds" do
    it "divides total latency by how many results produced it" do
      run = described_class.new("result_count" => 4, "total_latency_seconds" => 10.0)

      expect(run.average_latency_seconds).to eq(2.5)
    end

    it "is nil, not a division error, when there are no results yet" do
      run = described_class.new("result_count" => 0, "total_latency_seconds" => 0)

      expect(run.average_latency_seconds).to be_nil
    end
  end
end
