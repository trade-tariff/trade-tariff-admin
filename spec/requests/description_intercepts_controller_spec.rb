# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
RSpec.describe DescriptionInterceptsController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }
  let(:intercept_id) { "123" }
  let(:intercept_attributes) do
    {
      "term" => "animal feed",
      "excluded" => false,
      "message" => "Ask the trader to pick a more specific feed type.",
      "guidance_level" => "warning",
      "guidance_location" => "results",
      "escalate_to_webchat" => true,
      "filter_prefixes" => %w[1201 2309],
      "sources" => %w[guided_search],
      "aliases" => ["pet food", "animal nutrition"],
      "created_at" => "2026-04-15T10:30:00Z",
    }
  end

  let(:intercept_response) do
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: {
          type: "description_intercept",
          id: intercept_id,
          attributes: intercept_attributes,
        },
      }.to_json,
    }
  end

  describe "GET #index" do
    let(:make_request) { get description_intercepts_path }

    it { is_expected.to have_http_status :success }

    it "renders the intercepts page" do
      expect(rendered_page.body).to include("Intercepts")
      expect(rendered_page.body).to include("Description intercepts let you control how guided search behaves for known search terms.")
      expect(rendered_page.body).to include("Description Intercepts")
      expect(rendered_page.body).to include("Filtering enabled")
      expect(rendered_page.body).to include("Has guidance")
      expect(rendered_page.body).to include("Escalation enabled")
      expect(rendered_page.body).to include("Excluded")
      expect(rendered_page.body).to include("Commodity Intercepts (coming soon)")
      expect(rendered_page.body).to include("New description intercept")
    end
  end

  describe "GET #index with JSON format" do
    let(:make_request) do
      get description_intercepts_path(format: :json), params: {
        q: "animal",
        filtering: "true",
        escalates: "true",
        guidance: "true",
        excluded: "false",
      }
    end

    before do
      stub_api_request("/description_intercepts")
        .with(query: hash_including(
          "q" => "animal",
          "filtering" => "true",
          "escalates" => "true",
          "guidance" => "true",
          "excluded" => "false",
        ))
        .and_return(jsonapi_response("description_intercept", [intercept_attributes.merge("resource_id" => intercept_id)]))
    end

    it { is_expected.to have_http_status :success }

    it "returns the table payload" do
      json = JSON.parse(rendered_page.body)

      expect(json["data"]).to eq([
        {
          "id" => "123",
          "term" => "animal feed",
          "excluded" => false,
          "guidance" => "Ask the trader to pick a more specific feed type.",
          "guidance_present" => true,
          "filtering" => true,
          "behaviour" => "Filters to selected short codes",
          "escalates" => true,
          "created_at" => "15 April 2026",
        },
      ])
    end
  end

  describe "GET #new" do
    let(:make_request) { get new_description_intercept_path }

    it { is_expected.to have_http_status :success }

    it "shows the new form" do
      expect(rendered_page.body).to include("New description intercept")
      expect(rendered_page.body).to include("Create description intercept")
      expect(rendered_page.body).to include("Relevant Products")
      expect(rendered_page.body).not_to include("Guidance level")
      expect(rendered_page.body).not_to include("Guidance location")
    end

    it "defaults guided search to selected" do
      expect(rendered_page.body).to include('id="description_intercept_sources_guided_search"')
      expect(rendered_page.body).to match(/id="description_intercept_sources_guided_search"[\s\S]*?value="guided_search"[\s\S]*?checked/)
    end
  end

  describe "GET #show" do
    before do
      stub_api_request("/description_intercepts/#{intercept_id}")
        .and_return(intercept_response)
      stub_api_request("/versions")
        .with(query: hash_including("item_type" => "DescriptionIntercept", "item_id" => intercept_id))
        .and_return(status: 200, headers: { "content-type" => "application/json; charset=utf-8" }, body: { data: [] }.to_json)
      stub_api_request("/goods_nomenclature_autocomplete")
        .with(query: hash_including("q" => "1201"))
        .and_return(status: 200, headers: { "content-type" => "application/json; charset=utf-8" }, body: { data: [{ type: "goods_nomenclature_autocomplete", id: "1201", attributes: { "resource_id" => "1201", "goods_nomenclature_item_id" => "1201900000", "description" => "Soya bean flour and meal, whether or not defatted" } }] }.to_json)
      stub_api_request("/goods_nomenclature_autocomplete")
        .with(query: hash_including("q" => "2309"))
        .and_return(status: 200, headers: { "content-type" => "application/json; charset=utf-8" }, body: { data: [{ type: "goods_nomenclature_autocomplete", id: "2309", attributes: { "resource_id" => "2309", "goods_nomenclature_item_id" => "2309900000", "description" => "Preparations of a kind used in animal feeding" } }] }.to_json)
    end

    let(:make_request) { get description_intercept_path(intercept_id) }

    it { is_expected.to have_http_status :success }

    it "shows the description intercept details" do
      expect(rendered_page.body).to include("Description intercept")
      expect(rendered_page.body).to include("animal feed")
      expect(rendered_page.body).to include("Ask the trader to pick a more specific feed type.")
      expect(rendered_page.body).to include("Edit")
    end

    it "shows the full intercept summary" do
      expect(rendered_page.body).to include("Filters to selected short codes")
      expect(rendered_page.body).to include("Relevant Products")
      expect(rendered_page.body).to include("Guided search")
      expect(rendered_page.body).to include("pet food, animal nutrition")
      expect(rendered_page.body).to include("Soya bean flour and meal")
      expect(rendered_page.body).to include("Preparations of a kind used in animal feeding")
      expect(rendered_page.body).to include("Enabled")
      expect(rendered_page.body).to include("Not excluded")
      expect(rendered_page.body).not_to include("Guidance level")
      expect(rendered_page.body).not_to include("Guidance location")
    end

    context "when the intercept has no guidance" do
      let(:intercept_attributes) do
        super().merge(
          "message" => nil,
          "guidance_level" => nil,
          "guidance_location" => nil,
          "filter_prefixes" => [],
          "escalate_to_webchat" => false,
          "sources" => %w[fpo_search],
        )
      end

      it "shows guidance as none and hides level and location rows" do
        expect(rendered_page.body).to include("Guidance")
        expect(rendered_page.body).to include("None")
        expect(rendered_page.body).not_to include("Guidance level")
        expect(rendered_page.body).not_to include("Guidance location")
      end
    end
  end

  describe "GET #edit" do
    before do
      stub_api_request("/description_intercepts/#{intercept_id}")
        .and_return(intercept_response)
      stub_api_request("/goods_nomenclature_autocomplete")
        .with(query: hash_including("q" => "1201"))
        .and_return(status: 200, headers: { "content-type" => "application/json; charset=utf-8" }, body: { data: [{ type: "goods_nomenclature_autocomplete", id: "1201", attributes: { "resource_id" => "1201", "goods_nomenclature_item_id" => "1201900000", "description" => "Soya bean flour and meal, whether or not defatted" } }] }.to_json)
      stub_api_request("/goods_nomenclature_autocomplete")
        .with(query: hash_including("q" => "2309"))
        .and_return(status: 200, headers: { "content-type" => "application/json; charset=utf-8" }, body: { data: [{ type: "goods_nomenclature_autocomplete", id: "2309", attributes: { "resource_id" => "2309", "goods_nomenclature_item_id" => "2309900000", "description" => "Preparations of a kind used in animal feeding" } }] }.to_json)
    end

    let(:make_request) { get edit_description_intercept_path(intercept_id) }

    it { is_expected.to have_http_status :success }

    it "shows the edit form" do
      expect(rendered_page.body).to include("Save changes")
      expect(rendered_page.body).to include("Allow HMRC support escalation")
      expect(rendered_page.body).to include("Guidance message")
      expect(rendered_page.body).to include("Add alias")
      expect(rendered_page.body).to include("pet food")
      expect(rendered_page.body).to include("animal nutrition")
      expect(rendered_page.body).to include('name="description_intercept[aliases][]" value="pet food"')
      expect(rendered_page.body).to include('aria-label="Remove pet food"')
      expect(rendered_page.body).to include("Selected short codes")
      expect(rendered_page.body).not_to include("Guidance level")
      expect(rendered_page.body).not_to include("Guidance location")
    end

    it "renders the guidance message as a markdown editor with preview" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css ".govuk-grid-row .govuk-grid-column-one-half", count: 2
      expect(page).to have_css 'textarea.govuk-textarea[name="description_intercept[message]"]'
      expect(page).to have_css '.hott-markdown-preview[data-preview="govspeak"][data-preview-for="#description-intercept-message-field"]'
    end

    it "explains markdown and automatic short code links in a details component" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css ".govuk-details__summary-text", text: "Markdown and automatic short code links"
      expect(page).to have_css ".govuk-details__text", text: "Short codes are automatically rendered as links", visible: :all
      expect(page).to have_css ".govuk-details__text", text: "01", visible: :all
      expect(page).to have_css ".govuk-details__text", text: "0101", visible: :all
      expect(page).to have_css ".govuk-details__text", text: "010121", visible: :all
      expect(page).to have_css ".govuk-details__text", text: "0101210000", visible: :all
      expect(page).to have_link "Markdown guide", href: "https://govspeak-preview.publishing.service.gov.uk/guide", visible: :all
    end

    context "with a markdown guidance message" do
      let(:intercept_attributes) { super().merge("message" => "Ask the **trader** to pick a more specific feed type.") }

      it "renders the existing guidance message in the preview" do
        expect(Capybara.string(rendered_page.body)).to have_css ".hott-markdown-preview strong", text: "trader"
      end
    end

    it "shows remove controls for selected short codes" do
      expect(rendered_page.body).to include('aria-label="Remove 1201900000"')
      expect(rendered_page.body).to include('aria-label="Remove 2309900000"')
    end

    it "shows truncated descriptions for selected short codes" do
      expect(rendered_page.body).to include("Soya bean flour and meal")
      expect(rendered_page.body).to include("Preparations of a kind used in animal feeding")
    end

    context "when the intercept excludes search results" do
      let(:intercept_attributes) { super().merge("excluded" => true) }

      it "renders filtering as disabled" do
        expect(rendered_page.body).to include('id="description-intercept-filtering-enabled"')
        expect(rendered_page.body).to include('disabled="disabled"')
        expect(rendered_page.body).to include("Filtering is unavailable while exclude search results is selected.")
      end
    end

    context "when guided search is not selected" do
      let(:intercept_attributes) { super().merge("sources" => %w[fpo_search]) }

      it "hides guidance fields without clearing the existing value" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css '[data-description-intercept-form-target="guidanceFields"][style="display:none"]', visible: :all
        expect(page).to have_css 'textarea[name="description_intercept[message]"]', text: "Ask the trader to pick a more specific feed type.", visible: :all
      end
    end
  end

  describe "POST #create" do
    let(:make_request) do
      post description_intercepts_path, params: {
        description_intercept: {
          term: "new animal feed",
          excluded: "0",
          aliases: ["pet food", "animal nutrition"],
          message: "New guidance",
          guidance_level: "info",
          guidance_location: "results",
          escalate_to_webchat: "1",
          sources: %w[guided_search],
          filter_prefixes: %w[1201 2309],
        },
      }
    end

    context "with valid create" do
      before do
        stub_api_request("/description_intercepts", :post)
          .with { |request|
            attrs = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            attrs["message"] == "New guidance" &&
              attrs["aliases"] == ["pet food", "animal nutrition"] &&
              attrs["guidance_level"] == "info" &&
              attrs["guidance_location"] == "interstitial"
          }
          .and_return(
            status: 200,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: {
              data: {
                type: "description_intercept",
                id: "456",
                attributes: intercept_attributes.merge("term" => "new animal feed"),
              },
            }.to_json,
          )
      end

      it { is_expected.to redirect_to(description_intercept_path("456")) }

      it "shows a success message" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Description intercept created successfully.")
      end
    end

    context "with no sources selected" do
      let(:make_request) do
        post description_intercepts_path, params: {
          description_intercept: {
            term: "parked intercept",
            excluded: "0",
            aliases: [""],
            message: "",
            escalate_to_webchat: "0",
            sources: [""],
            filter_prefixes: [],
          },
        }
      end

      before do
        stub_api_request("/description_intercepts", :post)
          .with { |request|
            attrs = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            Array(attrs["sources"]).all?(&:blank?)
          }
          .and_return(
            status: 200,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: {
              data: {
                type: "description_intercept",
                id: "790",
                attributes: intercept_attributes.merge(
                  "term" => "parked intercept",
                  "message" => nil,
                  "guidance_level" => nil,
                  "guidance_location" => nil,
                  "escalate_to_webchat" => false,
                  "filter_prefixes" => [],
                  "sources" => [],
                ),
              },
            }.to_json,
          )
      end

      it "allows the intercept to be saved without sources" do
        expect(rendered_page).to redirect_to(description_intercept_path("790"))
      end
    end

    context "without guidance" do
      let(:make_request) do
        post description_intercepts_path, params: {
          description_intercept: {
            term: "plain term",
            excluded: "0",
            message: "",
            guidance_level: "info",
            guidance_location: "results",
            escalate_to_webchat: "0",
            sources: %w[guided_search],
            filter_prefixes: [],
          },
        }
      end

      before do
        stub_api_request("/description_intercepts", :post)
          .with { |request|
            attrs = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            attrs["message"].nil? &&
              attrs.key?("guidance_level") &&
              attrs["guidance_level"].nil? &&
              attrs.key?("guidance_location") &&
              attrs["guidance_location"].nil?
          }
          .and_return(
            status: 200,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: {
              data: {
                type: "description_intercept",
                id: "789",
                attributes: intercept_attributes.merge(
                  "term" => "plain term",
                  "message" => nil,
                  "guidance_level" => nil,
                  "guidance_location" => nil,
                  "escalate_to_webchat" => false,
                  "filter_prefixes" => [],
                ),
              },
            }.to_json,
          )
      end

      it "sends nil guidance fields and still creates the intercept" do
        expect(rendered_page).to redirect_to(description_intercept_path("789"))
      end
    end

    context "with invalid create" do
      before do
        stub_api_request("/description_intercepts", :post)
          .and_return(webmock_response(:error, term: "can't be blank"))
        stub_api_request("/goods_nomenclature_autocomplete")
          .with(query: hash_including("q" => "1201"))
          .and_return(status: 200, headers: { "content-type" => "application/json; charset=utf-8" }, body: { data: [{ type: "goods_nomenclature_autocomplete", id: "1201", attributes: { "resource_id" => "1201", "goods_nomenclature_item_id" => "1201900000", "description" => "Soya bean flour and meal, whether or not defatted" } }] }.to_json)
        stub_api_request("/goods_nomenclature_autocomplete")
          .with(query: hash_including("q" => "2309"))
          .and_return(status: 200, headers: { "content-type" => "application/json; charset=utf-8" }, body: { data: [{ type: "goods_nomenclature_autocomplete", id: "2309", attributes: { "resource_id" => "2309", "goods_nomenclature_item_id" => "2309900000", "description" => "Preparations of a kind used in animal feeding" } }] }.to_json)
      end

      it { is_expected.to have_http_status :unprocessable_content }
      it { is_expected.to render_template(:new) }
    end

    context "when exclude search results is selected" do
      let(:make_request) do
        post description_intercepts_path, params: {
          description_intercept: {
            term: "gift",
            excluded: "1",
            message: "",
            escalate_to_webchat: "0",
            sources: %w[fpo_search],
            filter_prefixes: %w[01 02],
          },
        }
      end

      before do
        stub_api_request("/description_intercepts", :post)
          .with { |request|
            attrs = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            attrs["excluded"] == "true" &&
              attrs.key?("filter_prefixes") &&
              Array(attrs["filter_prefixes"]).all?(&:blank?)
          }
          .and_return(
            status: 200,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: {
              data: {
                type: "description_intercept",
                id: "999",
                attributes: intercept_attributes.merge(
                  "term" => "gift",
                  "excluded" => true,
                  "message" => nil,
                  "guidance_level" => nil,
                  "guidance_location" => nil,
                  "escalate_to_webchat" => false,
                  "filter_prefixes" => [],
                  "sources" => %w[fpo_search],
                ),
              },
            }.to_json,
          )
      end

      it "sends empty filter prefixes in the payload" do
        expect(rendered_page).to redirect_to(description_intercept_path("999"))
      end
    end
  end

  describe "PATCH #update" do
    before do
      stub_api_request("/description_intercepts/#{intercept_id}")
        .and_return(intercept_response)
      stub_api_request("/goods_nomenclature_autocomplete")
        .with(query: hash_including("q" => "1201"))
        .and_return(status: 200, headers: { "content-type" => "application/json; charset=utf-8" }, body: { data: [{ type: "goods_nomenclature_autocomplete", id: "1201", attributes: { "resource_id" => "1201", "goods_nomenclature_item_id" => "1201900000", "description" => "Soya bean flour and meal, whether or not defatted" } }] }.to_json)
      stub_api_request("/goods_nomenclature_autocomplete")
        .with(query: hash_including("q" => "2309"))
        .and_return(status: 200, headers: { "content-type" => "application/json; charset=utf-8" }, body: { data: [{ type: "goods_nomenclature_autocomplete", id: "2309", attributes: { "resource_id" => "2309", "goods_nomenclature_item_id" => "2309900000", "description" => "Preparations of a kind used in animal feeding" } }] }.to_json)
    end

    let(:make_request) do
      patch description_intercept_path(intercept_id), params: {
        description_intercept: {
          term: "animal feed",
          excluded: "0",
          aliases: ["updated feed", "livestock feed"],
          message: "Updated guidance",
          guidance_level: "info",
          guidance_location: "question",
          escalate_to_webchat: "1",
          sources: %w[guided_search fpo_search],
          filter_prefixes: %w[1201 2309],
        },
      }
    end

    context "with valid update" do
      before do
        stub_api_request("/description_intercepts/#{intercept_id}", :patch)
          .with { |request|
            attrs = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            attrs["message"] == "Updated guidance" &&
              attrs["aliases"] == ["updated feed", "livestock feed"] &&
              attrs["guidance_level"] == "info" &&
              attrs["guidance_location"] == "interstitial"
          }
          .and_return(intercept_response)
      end

      it { is_expected.to redirect_to(description_intercept_path(intercept_id)) }

      it "shows a success message" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Description intercept updated successfully.")
      end
    end

    context "with invalid update" do
      before do
        stub_api_request("/description_intercepts/#{intercept_id}", :patch)
          .and_return(webmock_response(:error, filter_prefixes: "cannot be combined with excluded"))
        stub_api_request("/versions")
          .with(query: hash_including("item_type" => "DescriptionIntercept", "item_id" => intercept_id))
          .and_return(status: 200, headers: { "content-type" => "application/json; charset=utf-8" }, body: { data: [] }.to_json)
      end

      it { is_expected.to have_http_status :unprocessable_content }
      it { is_expected.to render_template(:edit) }

      it "links the error summary to the filter prefixes input" do
        expect(rendered_page.body).to include('href="#description-intercept-filter-prefixes-field-error"')
        expect(rendered_page.body).to include('id="description-intercept-filter-prefixes-error"')
      end
    end

    context "when exclude search results is selected" do
      let(:make_request) do
        patch description_intercept_path(intercept_id), params: {
          description_intercept: {
            term: "animal feed",
            excluded: "1",
            message: "",
            guidance_level: "info",
            guidance_location: "question",
            escalate_to_webchat: "0",
            sources: %w[fpo_search],
            filter_prefixes: %w[1201 2309],
          },
        }
      end

      before do
        stub_api_request("/description_intercepts/#{intercept_id}", :patch)
          .with { |request|
            attrs = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            attrs["excluded"] == "true" &&
              Array(attrs["filter_prefixes"]).all?(&:blank?) &&
              attrs["message"].nil? &&
              attrs["guidance_level"].nil? &&
              attrs["guidance_location"].nil?
          }
          .and_return(intercept_response.merge(status: 200))
      end

      it "drops filter prefixes from the payload" do
        expect(rendered_page).to redirect_to(description_intercept_path(intercept_id))
      end
    end

    context "when all selected short codes are removed" do
      let(:make_request) do
        patch description_intercept_path(intercept_id), params: {
          description_intercept: {
            term: "animal feed",
            excluded: "0",
            message: "Updated guidance",
            guidance_level: "info",
            guidance_location: "question",
            escalate_to_webchat: "1",
            sources: %w[guided_search],
          },
        }
      end

      before do
        stub_api_request("/description_intercepts/#{intercept_id}", :patch)
          .with { |request|
            attrs = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            attrs.key?("filter_prefixes") && Array(attrs["filter_prefixes"]).all?(&:blank?)
          }
          .and_return(intercept_response.merge(status: 200))
      end

      it "sends an empty filter prefix array" do
        expect(rendered_page).to redirect_to(description_intercept_path(intercept_id))
      end
    end

    context "when all sources are deselected" do
      let(:make_request) do
        patch description_intercept_path(intercept_id), params: {
          description_intercept: {
            term: "animal feed",
            excluded: "0",
            message: "Updated guidance",
            guidance_level: "info",
            guidance_location: "question",
            escalate_to_webchat: "1",
            filter_prefixes: %w[1201],
          },
        }
      end

      before do
        stub_api_request("/description_intercepts/#{intercept_id}", :patch)
          .with { |request|
            attrs = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            attrs.key?("sources") && Array(attrs["sources"]).all?(&:blank?)
          }
          .and_return(intercept_response.merge(status: 200))
      end

      it "sends an empty sources array" do
        expect(rendered_page).to redirect_to(description_intercept_path(intercept_id))
      end
    end

    context "when guidance is completely removed" do
      let(:make_request) do
        patch description_intercept_path(intercept_id), params: {
          description_intercept: {
            term: "animal feed",
            excluded: "0",
            message: "",
            guidance_level: "info",
            guidance_location: "question",
            escalate_to_webchat: "1",
            sources: %w[guided_search fpo_search],
            filter_prefixes: %w[1201 2309],
          },
        }
      end

      before do
        stub_api_request("/description_intercepts/#{intercept_id}", :patch)
          .with { |request|
            attrs = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            attrs["message"].nil? &&
              attrs["guidance_level"].nil? &&
              attrs["guidance_location"].nil?
          }
          .and_return(intercept_response.merge(status: 200))
      end

      it "sends nil guidance fields so the backend clears them" do
        expect(rendered_page).to redirect_to(description_intercept_path(intercept_id))
      end
    end
  end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
