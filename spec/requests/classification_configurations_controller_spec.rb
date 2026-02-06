# rubocop:disable RSpec/MultipleMemoizedHelpers, RSpec/MultipleExpectations, RSpec/ExampleLength
RSpec.describe ClassificationConfigurationsController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }
  let(:config_name) { "expansion_prompt" }
  let(:config_attributes) do
    {
      "name" => config_name,
      "value" => "You are a trade classification expert...",
      "config_type" => "markdown",
      "area" => "classification",
      "description" => "System prompt for query expansion",
      "deleted" => false,
    }
  end
  let(:config_response) do
    build_config_response(config_name, config_attributes)
  end
  let(:historical_config_response) do
    build_config_response(
      config_name,
      config_attributes.merge("value" => "Old prompt text"),
      version: { current: false, oid: 41, previous_oid: 40, has_previous_version: true },
    )
  end
  let(:collection_response) do
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
        ],
      }.to_json,
    }
  end

  around do |example|
    previous_environment = ENV["ENVIRONMENT"]
    ENV["ENVIRONMENT"] = "development"
    example.run
    ENV["ENVIRONMENT"] = previous_environment
  end

  before do
    cookies[TradeTariffAdmin.id_token_cookie_name] = id_token
  end

  describe "GET #index" do
    before do
      stub_api_request("/admin_configurations")
        .and_return(collection_response)
    end

    let(:make_request) { get classification_configurations_path }

    it { is_expected.to have_http_status :success }
    it { is_expected.to render_template(:index) }

    it "displays configurations with humanised names" do
      expect(rendered_page.body).to include("Classification Configurations")
      expect(rendered_page.body).to include("Expansion Prompt")
      expect(rendered_page.body).to include("Qa Enabled")
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

    it "displays boolean true values as green Yes tags" do
      expect(rendered_page.body).to include("govuk-tag--green")
      expect(rendered_page.body).to match(/Yes\s*<\/strong>/)
    end

    it "displays boolean false values as grey No tags" do
      expect(rendered_page.body).to include("govuk-tag--grey")
      expect(rendered_page.body).to match(/No\s*<\/strong>/)
    end

    it "displays integer values directly" do
      expect(rendered_page.body).to match(/>\s*250\s*</)
    end

    it "displays options values as selected label" do
      expect(rendered_page.body).to include("GPT-4o (multimodal)")
    end

    it "displays markdown/string values truncated" do
      expect(rendered_page.body).to include("You are a trade classification expert...")
    end

    context "when in production environment" do
      before do
        allow(TradeTariffAdmin).to receive(:environment).and_return("production")
      end

      it { is_expected.to have_http_status :not_found }
    end
  end

  describe "GET #show" do
    before do
      stub_api_request("/admin_configurations/#{config_name}")
        .and_return(config_response)
    end

    let(:make_request) { get classification_configuration_path(config_name) }

    it { is_expected.to have_http_status :success }
    it { is_expected.to render_template(:show) }

    it "displays configuration details" do
      expect(rendered_page.body).to include("Expansion Prompt")
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
      let(:config_name) { "label_model" }
      let(:config_attributes) do
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

      it "displays the options table with selected tag", :aggregate_failures do
        expect(rendered_page.body).to include("gpt-4o")
        expect(rendered_page.body).to include("GPT-4o (multimodal)")
        expect(rendered_page.body).to include("gpt-5.2")
        expect(rendered_page.body).to include("Selected")
      end
    end

    context "with a boolean config" do
      let(:config_name) { "qa_enabled" }
      let(:config_attributes) do
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
      let(:config_name) { "api_key_hint" }
      let(:config_attributes) do
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

    context "with an integer config" do
      let(:config_name) { "label_page_size" }
      let(:config_attributes) do
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

    context "when viewing a historical version" do
      before do
        stub_api_request("/admin_configurations/#{config_name}?filter%5Boid%5D=41")
          .and_return(historical_config_response)
      end

      let(:make_request) { get classification_configuration_path(config_name, oid: 41) }

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

      it { is_expected.to redirect_to(classification_configurations_path) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Configuration not found.")
      end
    end

    context "when in production environment" do
      before do
        allow(TradeTariffAdmin).to receive(:environment).and_return("production")
      end

      it { is_expected.to have_http_status :not_found }
    end
  end

  describe "GET #edit" do
    before do
      stub_api_request("/admin_configurations/#{config_name}")
        .and_return(config_response)
    end

    let(:make_request) { get edit_classification_configuration_path(config_name) }

    it { is_expected.to have_http_status :success }
    it { is_expected.to render_template(:edit) }

    context "with a markdown config" do
      it "renders the markdown editor with preview" do
        expect(rendered_page.body).to include("hott-markdown-preview")
      end
    end

    context "with an options config" do
      let(:config_name) { "label_model" }
      let(:config_attributes) do
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

      it "renders a select dropdown with options", :aggregate_failures do
        body = rendered_page.body
        expect(body).to include("options-selected-value")
        expect(body).to include("GPT-4o (multimodal)")
        expect(body).to include("GPT-5.2 (latest flagship)")
      end

      it "pre-selects the current value" do
        expect(rendered_page.body).to include('value="gpt-5.2" selected')
      end

      it "does not render add or remove option buttons" do
        expect(rendered_page.body).not_to include("Add option")
        expect(rendered_page.body).not_to include("Remove")
      end
    end

    context "with a boolean config" do
      let(:config_name) { "qa_enabled" }
      let(:config_attributes) do
        {
          "name" => "qa_enabled",
          "value" => true,
          "config_type" => "boolean",
          "area" => "classification",
          "description" => "Enable Q&A feature",
          "deleted" => false,
        }
      end

      it "renders radio buttons for Yes/No" do
        body = rendered_page.body
        expect(body).to include("Yes")
        expect(body).to include("No")
      end
    end

    context "with a string config" do
      let(:config_name) { "api_key_hint" }
      let(:config_attributes) do
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

    context "with an integer config" do
      let(:config_name) { "label_page_size" }
      let(:config_attributes) do
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

    it "does not render editable name, type, or description fields", :aggregate_failures do
      body = rendered_page.body
      expect(body).not_to include('name="classification_configuration[name]"')
      expect(body).not_to include('name="classification_configuration[config_type]"')
      expect(body).not_to include('name="classification_configuration[description]"')
    end

    context "when configuration is a historical version" do
      before do
        stub_api_request("/admin_configurations/#{config_name}")
          .and_return(historical_config_response)
      end

      it { is_expected.to redirect_to(classification_configuration_path(config_name)) }

      it "shows a historical version alert" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Cannot edit historical versions.")
      end
    end

    context "when in production environment" do
      before do
        allow(TradeTariffAdmin).to receive(:environment).and_return("production")
      end

      it { is_expected.to have_http_status :not_found }
    end
  end

  describe "PATCH #update" do
    before do
      stub_api_request("/admin_configurations/#{config_name}")
        .and_return(config_response)
    end

    let(:make_request) do
      patch classification_configuration_path(config_name),
            params: {
              classification_configuration: {
                value: "Updated prompt text",
              },
            }
    end

    context "with valid parameters" do
      before do
        stub_api_request("/admin_configurations/#{config_name}", :patch)
          .and_return(config_response)
      end

      it { is_expected.to redirect_to(classification_configuration_path(config_name)) }

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
      let(:config_name) { "label_model" }
      let(:options_json) do
        '{"selected":"gpt-4o","options":[{"key":"gpt-4o","label":"GPT-4o"},{"key":"gpt-5.2","label":"GPT-5.2"}]}'
      end
      let(:config_attributes) do
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
        patch classification_configuration_path(config_name),
              params: {
                classification_configuration: {
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

      it { is_expected.to redirect_to(classification_configuration_path(config_name)) }

      it "parses the JSON string value to a hash before sending to API" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Configuration updated.")
      end
    end

    context "with a boolean config value" do
      let(:config_name) { "qa_enabled" }
      let(:config_attributes) do
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
        patch classification_configuration_path(config_name),
              params: {
                classification_configuration: {
                  value: "false",
                },
              }
      end

      before do
        stub_api_request("/admin_configurations/#{config_name}", :patch)
          .and_return(config_response)
      end

      it { is_expected.to redirect_to(classification_configuration_path(config_name)) }
    end

    context "with a string config value" do
      let(:config_name) { "api_key_hint" }
      let(:config_attributes) do
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
        patch classification_configuration_path(config_name),
              params: {
                classification_configuration: {
                  value: "sk-new...key",
                },
              }
      end

      before do
        stub_api_request("/admin_configurations/#{config_name}", :patch)
          .and_return(config_response)
      end

      it { is_expected.to redirect_to(classification_configuration_path(config_name)) }
    end

    context "with an integer config value" do
      let(:config_name) { "label_page_size" }
      let(:config_attributes) do
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
        patch classification_configuration_path(config_name),
              params: {
                classification_configuration: {
                  value: "500",
                },
              }
      end

      before do
        stub_api_request("/admin_configurations/#{config_name}", :patch)
          .and_return(config_response)
      end

      it { is_expected.to redirect_to(classification_configuration_path(config_name)) }
    end

    context "when extra params are submitted" do
      let(:make_request) do
        patch classification_configuration_path(config_name),
              params: {
                classification_configuration: {
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

      it "ignores non-permitted params and keeps original values", :aggregate_failures do
        rendered_page

        # The PATCH was sent with the original model attributes, not the hacked ones
        expect(
          a_request(:patch, /admin_configurations/).with do |req|
            body = Rack::Utils.parse_nested_query(req.body)
            attrs = body.dig("data", "attributes")
            attrs["value"] == "Updated prompt text" &&
              attrs["name"] == config_name &&
              attrs["config_type"] == "markdown" &&
              attrs["description"] == "System prompt for query expansion"
          end,
        ).to have_been_made
      end
    end

    context "when configuration is a historical version" do
      before do
        stub_api_request("/admin_configurations/#{config_name}")
          .and_return(historical_config_response)
      end

      let(:make_request) do
        patch classification_configuration_path(config_name),
              params: {
                classification_configuration: {
                  value: "Updated prompt text",
                },
              }
      end

      it { is_expected.to redirect_to(classification_configuration_path(config_name)) }

      it "shows a historical version alert" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Cannot edit historical versions.")
      end
    end

    context "when in production environment" do
      before do
        allow(TradeTariffAdmin).to receive(:environment).and_return("production")
      end

      it { is_expected.to have_http_status :not_found }
    end
  end

  context "when on XI service" do
    before do
      TradeTariffAdmin::ServiceChooser.service_choice = "xi"
    end

    describe "GET #index" do
      before do
        stub_api_request("/admin_configurations")
          .and_return(collection_response)
      end

      let(:make_request) { get classification_configurations_path }

      it { is_expected.to render_template("errors/not_found") }
    end

    describe "GET #show" do
      before do
        stub_api_request("/admin_configurations/#{config_name}")
          .and_return(config_response)
      end

      let(:make_request) { get classification_configuration_path(config_name) }

      it { is_expected.to render_template("errors/not_found") }
    end

    describe "GET #edit" do
      before do
        stub_api_request("/admin_configurations/#{config_name}")
          .and_return(config_response)
      end

      let(:make_request) { get edit_classification_configuration_path(config_name) }

      it { is_expected.to render_template("errors/not_found") }
    end

    describe "PATCH #update" do
      before do
        stub_api_request("/admin_configurations/#{config_name}")
          .and_return(config_response)
      end

      let(:make_request) do
        patch classification_configuration_path(config_name),
              params: {
                classification_configuration: {
                  value: "Updated",
                },
              }
      end

      it { is_expected.to render_template("errors/not_found") }
    end
  end

  context "when user is HMRC admin (unauthorized)" do
    let(:current_user) { create(:user, :hmrc_admin) }

    describe "GET #index" do
      before do
        stub_api_request("/admin_configurations")
          .and_return(collection_response)
      end

      let(:make_request) { get classification_configurations_path }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  context "when user is auditor (unauthorized)" do
    let(:current_user) { create(:user, :auditor) }
    let(:make_request) { get classification_configurations_path }

    it { is_expected.to have_http_status :forbidden }
  end

  context "when user is guest (unauthorized)" do
    let(:current_user) { create(:user, :guest) }
    let(:make_request) { get classification_configurations_path }

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
# rubocop:enable RSpec/MultipleMemoizedHelpers, RSpec/MultipleExpectations, RSpec/ExampleLength
