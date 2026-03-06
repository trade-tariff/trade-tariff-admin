RSpec.describe AdminConfiguration do
  subject(:configuration) { described_class.new(attributes) }

  let(:attributes) do
    {
      name: "expansion_prompt",
      value: "You are a trade classification expert...",
      config_type: "markdown",
      area: "classification",
      description: "System prompt for query expansion",
    }
  end

  describe "#to_param" do
    it "returns the resource_id" do
      config = described_class.new(resource_id: "expansion_prompt", name: "expansion_prompt")
      expect(config.to_param).to eq("expansion_prompt")
    end

    it "returns nil when resource_id is not set" do
      config = described_class.new(name: "expansion_prompt")
      expect(config.to_param).to be_nil
    end
  end

  describe "#display_name" do
    it "titleizes the snake_case name" do
      config = described_class.new(name: "expand_query_context")
      expect(config.display_name).to eq("Expand Query Context")
    end

    it "returns nil when name is nil" do
      config = described_class.new(name: nil)
      expect(config.display_name).to be_nil
    end
  end

  describe "#current?" do
    it "returns true when version_current is not false" do
      configuration.version_current = true
      expect(configuration.current?).to be true
    end

    it "returns true when version_current is nil" do
      configuration.version_current = nil
      expect(configuration.current?).to be true
    end

    it "returns false when version_current is false" do
      configuration.version_current = false
      expect(configuration.current?).to be false
    end
  end

  describe "#has_previous_version?" do
    it "returns true when version_has_previous is true" do
      configuration.version_has_previous = true
      expect(configuration.has_previous_version?).to be true
    end

    it "returns false when version_has_previous is false" do
      configuration.version_has_previous = false
      expect(configuration.has_previous_version?).to be false
    end

    it "returns false when version_has_previous is nil" do
      configuration.version_has_previous = nil
      expect(configuration.has_previous_version?).to be false
    end
  end

  describe "#preview" do
    context "with markdown config_type" do
      let(:attributes) do
        {
          name: "test",
          value: "## Heading\n\nSome body text",
          config_type: "markdown",
        }
      end

      it "returns rendered HTML", :aggregate_failures do
        result = configuration.preview
        expect(result).to include("<h2")
        expect(result).to include("Heading")
      end
    end

    context "with non-markdown config_type" do
      let(:attributes) do
        {
          name: "test",
          value: "plain text",
          config_type: "string",
        }
      end

      it "returns nil" do
        expect(configuration.preview).to be_nil
      end
    end

    context "with blank value" do
      let(:attributes) do
        {
          name: "test",
          value: nil,
          config_type: "markdown",
        }
      end

      it "returns nil" do
        expect(configuration.preview).to be_nil
      end
    end
  end

  describe "#display_value" do
    context "with boolean type" do
      it "returns Yes for true" do
        config = described_class.new(name: "test", value: true, config_type: "boolean")
        expect(config.display_value).to eq("Yes")
      end

      it "returns No for false" do
        config = described_class.new(name: "test", value: false, config_type: "boolean")
        expect(config.display_value).to eq("No")
      end
    end

    context "with options type" do
      let(:attributes) do
        {
          name: "model_choice",
          config_type: "options",
          value: {
            "selected" => "claude",
            "options" => [
              { "key" => "claude", "label" => "Claude" },
              { "key" => "openai", "label" => "OpenAI" },
            ],
          },
        }
      end

      it "returns the selected option label" do
        expect(configuration.display_value).to eq("Claude")
      end
    end

    context "with integer type" do
      it "returns the value as a string" do
        config = described_class.new(name: "page_size", value: 250, config_type: "integer")
        expect(config.display_value).to eq("250")
      end
    end

    context "with string type" do
      let(:attributes) do
        {
          name: "test",
          value: "plain text",
          config_type: "string",
        }
      end

      it "returns the raw value" do
        expect(configuration.display_value).to eq("plain text")
      end
    end

    context "with model_config type" do
      let(:attributes) do
        {
          name: "search_model",
          config_type: "model_config",
          value: {
            "selected_model" => "gpt-5.2",
            "reasoning_effort" => "low",
            "models" => [
              { "key" => "gpt-5.2", "label" => "GPT-5.2 (latest flagship)" },
            ],
          },
        }
      end

      it "returns model label with reasoning effort" do
        expect(configuration.display_value).to eq("GPT-5.2 (latest flagship) (reasoning: low)")
      end
    end
  end

  describe "#selected_model_label" do
    context "with model_config type" do
      let(:attributes) do
        {
          name: "search_model",
          config_type: "model_config",
          value: {
            "selected_model" => "gpt-5.2",
            "reasoning_effort" => "low",
            "models" => [
              { "key" => "gpt-5.2", "label" => "GPT-5.2 (latest flagship)", "reasoning_levels" => %w[none low medium high] },
              { "key" => "gpt-4.1-2025-04-14", "label" => "GPT-4.1 (1M context)", "reasoning_levels" => [] },
            ],
          },
        }
      end

      it "returns the label for the selected model" do
        expect(configuration.selected_model_label).to eq("GPT-5.2 (latest flagship)")
      end
    end

    context "with non-model_config type" do
      it "returns nil" do
        expect(configuration.selected_model_label).to be_nil
      end
    end
  end

  describe "#selected_reasoning_effort" do
    context "with model_config type and reasoning set" do
      let(:attributes) do
        {
          name: "search_model",
          config_type: "model_config",
          value: {
            "selected_model" => "gpt-5.2",
            "reasoning_effort" => "low",
            "models" => [],
          },
        }
      end

      it "returns the reasoning effort" do
        expect(configuration.selected_reasoning_effort).to eq("low")
      end
    end

    context "with model_config type and no reasoning set" do
      let(:attributes) do
        {
          name: "expand_model",
          config_type: "model_config",
          value: {
            "selected_model" => "gpt-4.1-mini-2025-04-14",
            "reasoning_effort" => nil,
            "models" => [],
          },
        }
      end

      it "returns None" do
        expect(configuration.selected_reasoning_effort).to eq("None")
      end
    end

    context "with non-model_config type" do
      it "returns nil" do
        expect(configuration.selected_reasoning_effort).to be_nil
      end
    end
  end

  describe "#selected_option_label" do
    context "with options type" do
      let(:attributes) do
        {
          name: "provider",
          config_type: "options",
          value: {
            "selected" => "openai",
            "options" => [
              { "key" => "claude", "label" => "Claude" },
              { "key" => "openai", "label" => "OpenAI" },
            ],
          },
        }
      end

      it "returns the label for the selected option" do
        expect(configuration.selected_option_label).to eq("OpenAI")
      end
    end

    context "with non-options type" do
      let(:attributes) do
        {
          name: "test",
          value: "text",
          config_type: "string",
        }
      end

      it "returns nil" do
        expect(configuration.selected_option_label).to be_nil
      end
    end
  end
end
