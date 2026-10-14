RSpec.describe ConfigurationsController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :superadmin) }

  def config_name
    "expansion_prompt"
  end

  def config_attributes
    {
      "name" => config_name,
      "value" => "You are a trade classification expert...",
      "config_type" => "markdown",
      "area" => "classification",
      "description" => "System prompt for query expansion",
      "deleted" => false,
    }
  end

  def config_response
    build_config_response(config_name, config_attributes)
  end

  def historical_config_response
    build_config_response(
      config_name,
      config_attributes.merge("value" => "Old prompt text"),
      version: { current: false, oid: 41, previous_oid: 40, has_previous_version: true },
    )
  end

  def collection_response
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: [
          {
            type: "admin_configuration",
            id: config_name,
            attributes: config_attributes,
          },
          {
            type: "admin_configuration",
            id: "qa_enabled",
            attributes: {
              "name" => "qa_enabled",
              "value" => true,
              "config_type" => "boolean",
              "area" => "classification",
              "description" => "Enable Q&A feature",
              "deleted" => false,
            },
          },
          {
            type: "admin_configuration",
            id: "debug_mode",
            attributes: {
              "name" => "debug_mode",
              "value" => false,
              "config_type" => "boolean",
              "area" => "classification",
              "description" => "Enable debug mode",
              "deleted" => false,
            },
          },
          {
            type: "admin_configuration",
            id: "batch_size",
            attributes: {
              "name" => "batch_size",
              "value" => 250,
              "config_type" => "integer",
              "area" => "classification",
              "description" => "Batch processing size",
              "deleted" => false,
            },
          },
          {
            type: "admin_configuration",
            id: "model_selection",
            attributes: {
              "name" => "model_selection",
              "value" => {
                "selected" => "gpt-4o",
                "options" => [
                  { "key" => "gpt-4o", "label" => "GPT-4o (multimodal)" },
                  { "key" => "gpt-5", "label" => "GPT-5 (latest)" },
                ],
              },
              "config_type" => "options",
              "area" => "classification",
              "description" => "AI model selection",
              "deleted" => false,
            },
          },
          {
            type: "admin_configuration",
            id: "interactive_search_excluded_chapters",
            attributes: {
              "name" => "interactive_search_excluded_chapters",
              "value" => {
                "selected" => %w[98 99],
                "options" => [
                  { "key" => "98", "label" => "Chapter 98" },
                  { "key" => "99", "label" => "Chapter 99" },
                ],
              },
              "config_type" => "multi_options",
              "area" => "classification",
              "description" => "Chapters excluded from guided search results",
              "deleted" => false,
            },
          },
          {
            type: "admin_configuration",
            id: "description_intercept_templates",
            attributes: {
              "name" => "description_intercept_templates",
              "value" => {
                "vague" => {
                  "label" => "Vague term",
                  "description" => "Use when the term is too broad to classify safely.",
                  "attributes" => { "excluded" => true },
                },
              },
              "config_type" => "object_template",
              "area" => "classification",
              "description" => "Named templates used by the description intercept bulk import",
              "deleted" => false,
            },
          },
        ],
      }.to_json,
    }
  end

  before do
    cookies[TradeTariffAdmin.id_token_cookie_name] = id_token
  end

  describe "GET #index" do
    before do
      stub_api_request("/admin_configurations")
        .and_return(collection_response)
    end

    let(:make_request) { get configurations_path }

    it { is_expected.to have_http_status :success }
    it { is_expected.to render_template(:index) }

    it "displays the configurations heading" do
      expect(rendered_page.body).to include("Configurations")
    end

    it "displays the expansion prompt name" do
      expect(rendered_page.body).to include("Expansion Prompt")
    end

    it "displays the qa enabled name" do
      expect(rendered_page.body).to include("Qa Enabled")
    end

    it "displays the object template type" do
      expect(rendered_page.body).to include("Object template")
    end

    it "displays the template count" do
      expect(rendered_page.body).to include("1 template")
    end

    it "does not display a new configuration button" do
      expect(rendered_page.body).not_to include("New configuration")
    end

    it "does not display delete links" do
      expect(rendered_page.body).not_to include("Delete")
    end

    it "sorts configurations by type then name" do
      body = rendered_page.body
      boolean_pos = body.index("Qa Enabled")
      markdown_pos = body.index("Expansion Prompt")

      expect(boolean_pos).to be < markdown_pos
    end

    it "displays boolean true values as green tags" do
      expect(rendered_page.body).to include("govuk-tag--green")
    end

    it "displays boolean true values as yes" do
      expect(rendered_page.body).to match(/Yes\s*<\/strong>/)
    end

    it "displays boolean false values as grey tags" do
      expect(rendered_page.body).to include("govuk-tag--grey")
    end

    it "displays boolean false values as no" do
      expect(rendered_page.body).to match(/No\s*<\/strong>/)
    end

    it "displays integer values directly" do
      expect(rendered_page.body).to match(/>\s*250\s*</)
    end

    it "displays options values as selected label" do
      expect(rendered_page.body).to include("GPT-4o (multimodal)")
    end

    it "displays multi_options values as selected labels" do
      expect(rendered_page.body).to include("Chapter 98, Chapter 99")
    end

    it "displays markdown/string values truncated" do
      expect(rendered_page.body).to include("You are a trade classification expert...")
    end
  end

  describe "GET #show" do
    before do
      stub_api_request("/admin_configurations/#{config_name}")
        .and_return(config_response)
      stub_request(:get, /admin\/versions/)
        .and_return(status: 200, headers: { "content-type" => "application/json; charset=utf-8" }, body: { data: [] }.to_json)
    end

    let(:make_request) { get configuration_path(config_name) }

    it { is_expected.to have_http_status :success }
    it { is_expected.to render_template(:show) }

    it "displays the configuration name" do
      expect(rendered_page.body).to include("Expansion Prompt")
    end

    it "displays the configuration description" do
      expect(rendered_page.body).to include("System prompt for query expansion")
    end

    it "displays the edit button when current" do
      expect(rendered_page.body).to include("Edit")
    end

    it "displays the previous version link" do
      expect(rendered_page.body).to include("Previous version")
    end

    context "with a markdown config" do
      it "renders the markdown preview" do
        expect(rendered_page.body).to include("hott-markdown-preview")
      end
    end

    context "with an options config" do
      def config_name
        "label_model"
      end

      def config_attributes
        {
          "name" => "label_model",
          "value" => {
            "selected" => "gpt-5.2",
            "options" => [
              { "key" => "gpt-4o", "label" => "GPT-4o (multimodal)" },
              { "key" => "gpt-5.2", "label" => "GPT-5.2 (latest flagship)" },
            ],
          },
          "config_type" => "options",
          "area" => "classification",
          "description" => "AI model used for commodity labelling",
          "deleted" => false,
        }
      end

      it "displays the unselected option key" do
        expect(rendered_page.body).to include("gpt-4o")
      end

      it "displays the unselected option label" do
        expect(rendered_page.body).to include("GPT-4o (multimodal)")
      end

      it "displays the selected option key" do
        expect(rendered_page.body).to include("gpt-5.2")
      end

      it "displays the selected tag" do
        expect(rendered_page.body).to include("Selected")
      end
    end

    context "with a boolean config" do
      def config_name
        "qa_enabled"
      end

      def config_attributes
        {
          "name" => "qa_enabled",
          "value" => true,
          "config_type" => "boolean",
          "area" => "classification",
          "description" => "Enable Q&A feature",
          "deleted" => false,
        }
      end

      it "displays the boolean value as Yes" do
        expect(rendered_page.body).to include("Yes")
      end
    end

    context "with a string config" do
      def config_name
        "api_key_hint"
      end

      def config_attributes
        {
          "name" => "api_key_hint",
          "value" => "sk-abc...xyz",
          "config_type" => "string",
          "area" => "classification",
          "description" => "Hint for the API key",
          "deleted" => false,
        }
      end

      it "displays the string value in a pre block" do
        expect(rendered_page.body).to include("<pre>sk-abc...xyz</pre>")
      end
    end

    context "with an object template config" do
      def config_name
        "description_intercept_templates"
      end

      def config_attributes
        {
          "name" => "description_intercept_templates",
          "value" => {
            "vague" => {
              "label" => "Vague term",
              "description" => "Use when the term is too broad to classify safely.",
              "attributes" => {
                "escalate_to_webchat" => false,
                "excluded" => true,
                "sources" => %w[guided_search fpo_search],
              },
            },
          },
          "config_type" => "object_template",
          "area" => "classification",
          "description" => "Named templates used by the description intercept bulk import",
          "deleted" => false,
        }
      end

      it "displays the object templates heading" do
        expect(rendered_page.body).to include("Object templates")
      end

      it "displays the template key" do
        expect(rendered_page.body).to include("vague")
      end

      it "displays the template label" do
        expect(rendered_page.body).to include("Vague term")
      end

      it "displays the description column" do
        expect(rendered_page.body).to include("Description")
      end

      it "displays the escalate to webchat column" do
        expect(rendered_page.body).to include("Escalate to webchat")
      end

      it "displays the excluded column" do
        expect(rendered_page.body).to include("Excluded")
      end

      it "displays yes for a true template flag" do
        expect(rendered_page.body).to include("Yes")
      end

      it "displays no for a false template flag" do
        expect(rendered_page.body).to include("No")
      end

      it "displays the guided search source" do
        expect(rendered_page.body).to include("guided_search")
      end

      it "does not display the raw attribute key" do
        expect(rendered_page.body).not_to include(">escalate_to_webchat<")
      end

      it "does not display the raw template JSON" do
        expect(rendered_page.body).not_to include("<pre>{&quot;vague&quot;")
      end
    end

    context "with an integer config" do
      def config_name
        "label_page_size"
      end

      def config_attributes
        {
          "name" => "label_page_size",
          "value" => 250,
          "config_type" => "integer",
          "area" => "classification",
          "description" => "Number of commodities processed per batch",
          "deleted" => false,
        }
      end

      it "displays the integer value in a pre block" do
        expect(rendered_page.body).to include("<pre>250</pre>")
      end
    end

    context "with a multi_options config" do
      def config_name
        "interactive_search_excluded_chapters"
      end

      def config_attributes
        {
          "name" => "interactive_search_excluded_chapters",
          "value" => {
            "selected" => %w[98 99],
            "options" => [
              { "key" => "97", "label" => "Chapter 97" },
              { "key" => "98", "label" => "Chapter 98" },
              { "key" => "99", "label" => "Chapter 99" },
            ],
          },
          "config_type" => "multi_options",
          "area" => "classification",
          "description" => "Chapters excluded from guided search results",
          "deleted" => false,
        }
      end

      it "displays the selected chapter 98 label" do
        expect(rendered_page.body).to include("Chapter 98")
      end

      it "displays the selected chapter 99 label" do
        expect(rendered_page.body).to include("Chapter 99")
      end

      it "displays the unselected chapter 97 label" do
        expect(rendered_page.body).to include("Chapter 97")
      end
    end

    context "when viewing a historical version" do
      before do
        stub_api_request("/admin_configurations/#{config_name}?filter%5Boid%5D=41")
          .and_return(historical_config_response)
      end

      let(:make_request) { get configuration_path(config_name, oid: 41) }

      it { is_expected.to have_http_status :success }

      it "displays the historical version banner" do
        expect(rendered_page.body).to include("historical version")
      end

      it "does not display the edit button" do
        expect(rendered_page.body).not_to include("Edit")
      end

      it "displays the current version link" do
        expect(rendered_page.body).to include("Current version")
      end
    end

    context "when configuration not found" do
      before do
        stub_api_request("/admin_configurations/#{config_name}")
          .and_return(status: 404, body: { error: "Not found" }.to_json)
      end

      it { is_expected.to redirect_to(configurations_path) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Configuration not found.")
      end
    end

    context "when current user is technical operator" do
      let(:current_user) { create(:user, :technical_operator) }

      it { is_expected.to have_http_status(:success) }

      it "hides the edit button" do
        expect(rendered_page.body).not_to include("Edit")
      end
    end

    context "when current user is auditor" do
      let(:current_user) { create(:user, :auditor) }

      it { is_expected.to have_http_status(:success) }

      it "hides the edit button" do
        expect(rendered_page.body).not_to include("Edit")
      end
    end
  end

  describe "GET #edit" do
    before do
      stub_api_request("/admin_configurations/#{config_name}")
        .and_return(config_response)
    end

    let(:make_request) { get edit_configuration_path(config_name) }

    it { is_expected.to have_http_status :success }
    it { is_expected.to render_template(:edit) }

    context "with a markdown config" do
      it "renders the markdown editor with preview" do
        expect(rendered_page.body).to include("hott-markdown-preview")
      end
    end

    context "with an options config" do
      def config_name
        "label_model"
      end

      def config_attributes
        {
          "name" => "label_model",
          "value" => {
            "selected" => "gpt-5.2",
            "options" => [
              { "key" => "gpt-4o", "label" => "GPT-4o (multimodal)" },
              { "key" => "gpt-5.2", "label" => "GPT-5.2 (latest flagship)" },
            ],
          },
          "config_type" => "options",
          "area" => "classification",
          "description" => "AI model used for commodity labelling",
          "deleted" => false,
        }
      end

      it "renders the selected value field" do
        expect(rendered_page.body).to include("options-selected-value")
      end

      it "renders the first option label" do
        expect(rendered_page.body).to include("GPT-4o (multimodal)")
      end

      it "renders the second option label" do
        expect(rendered_page.body).to include("GPT-5.2 (latest flagship)")
      end

      it "pre-selects the current value" do
        expect(rendered_page.body).to include('value="gpt-5.2" selected')
      end

      it "does not render an add option button" do
        expect(rendered_page.body).not_to include("Add option")
      end

      it "does not render a remove button" do
        expect(rendered_page.body).not_to include("Remove")
      end

      it "uses the config form controller" do
        expect(rendered_page.body).to include('data-controller="config-form"')
      end

      it "updates the option on change" do
        expect(rendered_page.body).to include('data-action="change->config-form#updateOption"')
      end

      it "does not use an onchange attribute" do
        expect(rendered_page.body).not_to include("onchange=")
      end

      it "does not include a script tag" do
        expect(rendered_page.body).not_to include("<script>")
      end
    end

    context "with a boolean config" do
      def config_name
        "qa_enabled"
      end

      def config_attributes
        {
          "name" => "qa_enabled",
          "value" => true,
          "config_type" => "boolean",
          "area" => "classification",
          "description" => "Enable Q&A feature",
          "deleted" => false,
        }
      end

      it "renders a yes choice" do
        expect(rendered_page.body).to include("Yes")
      end

      it "renders a no choice" do
        expect(rendered_page.body).to include("No")
      end
    end

    context "with a string config" do
      def config_name
        "api_key_hint"
      end

      def config_attributes
        {
          "name" => "api_key_hint",
          "value" => "sk-abc...xyz",
          "config_type" => "string",
          "area" => "classification",
          "description" => "Hint for the API key",
          "deleted" => false,
        }
      end

      it "renders a text area" do
        expect(rendered_page.body).to include("sk-abc...xyz")
      end
    end

    context "with a description intercept templates config" do
      def config_name
        "description_intercept_templates"
      end

      def config_attributes
        {
          "name" => "description_intercept_templates",
          "value" => {
            "vague" => {
              "label" => "Vague term",
              "description" => "Use when the term is too broad to classify safely.",
              "attributes" => { "excluded" => true },
            },
          },
          "config_type" => "object_template",
          "area" => "classification",
          "description" => "Named templates used by the description intercept bulk import",
          "deleted" => false,
        }
      end

      it "renders the template configuration label" do
        expect(rendered_page.body).to include("Template configuration")
      end

      it "renders the template key as JSON" do
        expect(rendered_page.body).to include("&quot;vague&quot;")
      end

      it "renders the label key as JSON" do
        expect(rendered_page.body).to include("&quot;label&quot;")
      end
    end

    context "with an integer config" do
      def config_name
        "label_page_size"
      end

      def config_attributes
        {
          "name" => "label_page_size",
          "value" => 250,
          "config_type" => "integer",
          "area" => "classification",
          "description" => "Number of commodities processed per batch",
          "deleted" => false,
        }
      end

      it "renders a number field" do
        expect(rendered_page.body).to include('type="number"')
      end
    end

    context "with a multi_options config" do
      def config_name
        "interactive_search_excluded_chapters"
      end

      def config_attributes
        {
          "name" => "interactive_search_excluded_chapters",
          "value" => {
            "selected" => %w[98 99],
            "options" => [
              { "key" => "97", "label" => "Chapter 97" },
              { "key" => "98", "label" => "Chapter 98" },
              { "key" => "99", "label" => "Chapter 99" },
            ],
          },
          "config_type" => "multi_options",
          "area" => "classification",
          "description" => "Chapters excluded from guided search results",
          "deleted" => false,
        }
      end

      it "renders a checkbox" do
        expect(rendered_page.body).to include('type="checkbox"')
      end

      it "renders chapter 97" do
        expect(rendered_page.body).to include("Chapter 97")
      end

      it "renders chapter 98" do
        expect(rendered_page.body).to include("Chapter 98")
      end

      it "renders chapter 99" do
        expect(rendered_page.body).to include("Chapter 99")
      end

      it "uses the config form controller" do
        expect(rendered_page.body).to include('data-controller="config-form"')
      end

      it "updates the multi option on change" do
        expect(rendered_page.body).to include('data-action="change->config-form#updateMultiOption"')
      end

      it "does not use an onchange attribute" do
        expect(rendered_page.body).not_to include("onchange=")
      end

      it "does not include a script tag" do
        expect(rendered_page.body).not_to include("<script>")
      end
    end

    context "with a nested_options config" do
      def config_name
        "search_term_confidence_thresholds"
      end

      def config_attributes
        {
          "name" => "search_term_confidence_thresholds",
          "value" => {
            "selected" => "strict",
            "options" => [
              {
                "key" => "strict",
                "label" => "Strict",
                "sub_options" => {
                  "minimum_confidence" => %w[high medium low],
                },
              },
              {
                "key" => "relaxed",
                "label" => "Relaxed",
                "sub_options" => {
                  "minimum_confidence" => %w[medium low],
                },
              },
            ],
            "sub_values" => {
              "minimum_confidence" => "medium",
            },
          },
          "config_type" => "nested_options",
          "area" => "classification",
          "description" => "Thresholds for search term confidence",
          "deleted" => false,
        }
      end

      it "uses the config form controller" do
        expect(rendered_page.body).to include('data-controller="config-form"')
      end

      it "updates the nested option on change" do
        expect(rendered_page.body).to include('data-action="change->config-form#updateNestedOption"')
      end

      it "marks the nested sub options container" do
        expect(rendered_page.body).to include('data-config-form-target="nestedSubOptionsContainer"')
      end

      it "does not use an onchange attribute" do
        expect(rendered_page.body).not_to include("onchange=")
      end

      it "does not include a script tag" do
        expect(rendered_page.body).not_to include("<script>")
      end
    end

    it "does not render a name field" do
      expect(rendered_page.body).not_to include('name="configuration[name]"')
    end

    it "does not render a type field" do
      expect(rendered_page.body).not_to include('name="configuration[config_type]"')
    end

    it "does not render a description field" do
      expect(rendered_page.body).not_to include('name="configuration[description]"')
    end

    context "when configuration is a historical version" do
      before do
        stub_api_request("/admin_configurations/#{config_name}")
          .and_return(historical_config_response)
      end

      it { is_expected.to redirect_to(configuration_path(config_name)) }

      it "shows a historical version alert" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Cannot edit historical versions.")
      end
    end
  end

  describe "PATCH #update" do
    before do
      stub_api_request("/admin_configurations/#{config_name}")
        .and_return(config_response)
    end

    let(:make_request) do
      patch configuration_path(config_name),
            params: {
              configuration: {
                value: "Updated prompt text",
              },
            }
    end

    context "with valid parameters" do
      before do
        stub_api_request("/admin_configurations/#{config_name}", :patch)
          .and_return(config_response)
      end

      it { is_expected.to redirect_to(configuration_path(config_name)) }

      it "shows a success message" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Configuration updated.")
      end
    end

    context "with invalid parameters" do
      before do
        stub_api_request("/admin_configurations/#{config_name}", :patch)
          .and_return(webmock_response(:error, value: "can't be blank"))
      end

      it { is_expected.to have_http_status :ok }
      it { is_expected.to render_template(:edit) }
    end

    context "with an options config JSON value" do
      def config_name
        "label_model"
      end

      def options_json
        '{"selected":"gpt-4o","options":[{"key":"gpt-4o","label":"GPT-4o"},{"key":"gpt-5.2","label":"GPT-5.2"}]}'
      end

      def config_attributes
        {
          "name" => "label_model",
          "value" => JSON.parse(options_json),
          "config_type" => "options",
          "area" => "classification",
          "description" => "AI model used for commodity labelling",
          "deleted" => false,
        }
      end
      let(:make_request) do
        patch configuration_path(config_name),
              params: {
                configuration: {
                  value: options_json,
                },
              }
      end

      before do
        stub_api_request("/admin_configurations/#{config_name}", :patch)
          .with(body: hash_including(
            "data" => hash_including(
              "attributes" => hash_including(
                "value" => { "selected" => "gpt-4o", "options" => [{ "key" => "gpt-4o", "label" => "GPT-4o" }, { "key" => "gpt-5.2", "label" => "GPT-5.2" }] },
              ),
            ),
          ))
          .and_return(config_response)
      end

      it { is_expected.to redirect_to(configuration_path(config_name)) }

      it "parses the JSON string value to a hash before sending to API" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Configuration updated.")
      end
    end

    context "with a boolean config value" do
      def config_name
        "qa_enabled"
      end

      def config_attributes
        {
          "name" => "qa_enabled",
          "value" => true,
          "config_type" => "boolean",
          "area" => "classification",
          "description" => "Enable Q&A feature",
          "deleted" => false,
        }
      end
      let(:make_request) do
        patch configuration_path(config_name),
              params: {
                configuration: {
                  value: "false",
                },
              }
      end

      before do
        stub_api_request("/admin_configurations/#{config_name}", :patch)
          .and_return(config_response)
      end

      it { is_expected.to redirect_to(configuration_path(config_name)) }
    end

    context "with a string config value" do
      def config_name
        "api_key_hint"
      end

      def config_attributes
        {
          "name" => "api_key_hint",
          "value" => "sk-abc...xyz",
          "config_type" => "string",
          "area" => "classification",
          "description" => "Hint for the API key",
          "deleted" => false,
        }
      end
      let(:make_request) do
        patch configuration_path(config_name),
              params: {
                configuration: {
                  value: "sk-new...key",
                },
              }
      end

      before do
        stub_api_request("/admin_configurations/#{config_name}", :patch)
          .and_return(config_response)
      end

      it { is_expected.to redirect_to(configuration_path(config_name)) }
    end

    context "with an integer config value" do
      def config_name
        "label_page_size"
      end

      def config_attributes
        {
          "name" => "label_page_size",
          "value" => 250,
          "config_type" => "integer",
          "area" => "classification",
          "description" => "Number of commodities processed per batch",
          "deleted" => false,
        }
      end
      let(:make_request) do
        patch configuration_path(config_name),
              params: {
                configuration: {
                  value: "500",
                },
              }
      end

      before do
        stub_api_request("/admin_configurations/#{config_name}", :patch)
          .and_return(config_response)
      end

      it { is_expected.to redirect_to(configuration_path(config_name)) }
    end

    context "with a multi_options config JSON value" do
      def config_name
        "interactive_search_excluded_chapters"
      end

      def multi_options_json
        '{"selected":["97","99"],"options":[{"key":"97","label":"Chapter 97"},{"key":"98","label":"Chapter 98"},{"key":"99","label":"Chapter 99"}]}'
      end

      def config_attributes
        {
          "name" => "interactive_search_excluded_chapters",
          "value" => JSON.parse(multi_options_json),
          "config_type" => "multi_options",
          "area" => "classification",
          "description" => "Chapters excluded from guided search results",
          "deleted" => false,
        }
      end
      let(:make_request) do
        patch configuration_path(config_name),
              params: {
                configuration: {
                  value: multi_options_json,
                },
              }
      end

      before do
        stub_api_request("/admin_configurations/#{config_name}", :patch)
          .with(body: hash_including(
            "data" => hash_including(
              "attributes" => hash_including(
                "value" => {
                  "selected" => %w[97 99],
                  "options" => [
                    { "key" => "97", "label" => "Chapter 97" },
                    { "key" => "98", "label" => "Chapter 98" },
                    { "key" => "99", "label" => "Chapter 99" },
                  ],
                },
              ),
            ),
          ))
          .and_return(config_response)
      end

      it { is_expected.to redirect_to(configuration_path(config_name)) }
    end

    context "when extra params are submitted" do
      let(:make_request) do
        patch configuration_path(config_name),
              params: {
                configuration: {
                  value: "Updated prompt text",
                  name: "hacked_name",
                  config_type: "boolean",
                  description: "hacked description",
                  area: "hacked_area",
                },
              }
      end

      before do
        stub_api_request("/admin_configurations/#{config_name}", :patch)
          .and_return(config_response)
      end

      it "sends the updated value" do
        rendered_page

        expect(update_with_attribute("value", "Updated prompt text")).to have_been_made
      end

      it "keeps the original name" do
        rendered_page

        expect(update_with_attribute("name", config_name)).to have_been_made
      end

      it "keeps the markdown type" do
        rendered_page

        expect(update_with_attribute("config_type", "markdown")).to have_been_made
      end

      it "keeps the original description" do
        rendered_page

        expect(update_with_attribute("description", "System prompt for query expansion")).to have_been_made
      end

      def update_with_attribute(key, expected)
        a_request(:patch, /admin_configurations/).with do |request|
          attrs = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
          attrs[key] == expected
        end
      end
    end

    context "when configuration is a historical version" do
      before do
        stub_api_request("/admin_configurations/#{config_name}")
          .and_return(historical_config_response)
      end

      let(:make_request) do
        patch configuration_path(config_name),
              params: {
                configuration: {
                  value: "Updated prompt text",
                },
              }
      end

      it { is_expected.to redirect_to(configuration_path(config_name)) }

      it "shows a historical version alert" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Cannot edit historical versions.")
      end
    end
  end

  context "when user is HMRC admin (unauthorized)" do
    let(:current_user) { create(:user, :hmrc_admin) }

    describe "GET #index" do
      before do
        stub_api_request("/admin_configurations")
          .and_return(collection_response)
      end

      let(:make_request) { get configurations_path }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  context "when user is technical operator (read-only)" do
    let(:current_user) { create(:user, :technical_operator) }

    describe "GET #index" do
      before do
        stub_api_request("/admin_configurations")
          .and_return(collection_response)
      end

      let(:make_request) { get configurations_path }

      it { is_expected.to have_http_status :success }
    end

    describe "GET #edit" do
      before do
        stub_api_request("/admin_configurations/#{config_name}")
          .and_return(config_response)
      end

      let(:make_request) { get edit_configuration_path(config_name) }

      it { is_expected.to have_http_status :forbidden }
    end

    describe "PATCH #update" do
      before do
        stub_api_request("/admin_configurations/#{config_name}")
          .and_return(config_response)
      end

      let(:make_request) do
        patch configuration_path(config_name),
              params: { configuration: { value: "Updated prompt text" } }
      end

      it { is_expected.to have_http_status :forbidden }
    end
  end

  context "when user is auditor (read-only)" do
    let(:current_user) { create(:user, :auditor) }

    describe "GET #index" do
      before do
        stub_api_request("/admin_configurations")
          .and_return(collection_response)
      end

      let(:make_request) { get configurations_path }

      it { is_expected.to have_http_status :success }
    end

    describe "GET #edit" do
      before do
        stub_api_request("/admin_configurations/#{config_name}")
          .and_return(config_response)
      end

      let(:make_request) { get edit_configuration_path(config_name) }

      it { is_expected.to have_http_status :forbidden }
    end

    describe "PATCH #update" do
      before do
        stub_api_request("/admin_configurations/#{config_name}")
          .and_return(config_response)
      end

      let(:make_request) do
        patch configuration_path(config_name),
              params: { configuration: { value: "Updated prompt text" } }
      end

      it { is_expected.to have_http_status :forbidden }
    end
  end

  context "when user is guest (unauthorized)" do
    let(:current_user) { create(:user, :guest) }
    let(:make_request) { get configurations_path }

    it { is_expected.to have_http_status :forbidden }
  end

  def build_config_response(name, attributes, version: nil)
    version ||= { current: true, oid: 42, previous_oid: 41, has_previous_version: true }

    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: {
          type: "admin_configuration",
          id: name,
          attributes: attributes,
        },
        meta: {
          version: version,
        },
      }.to_json,
    }
  end
end
