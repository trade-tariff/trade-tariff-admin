RSpec.describe DescriptionIntercept do
  subject(:intercept) { described_class.new(attributes) }

  let(:attributes) do
    {
      resource_id: 123,
      term: "animal feed",
      excluded: false,
      message: "Show this guidance message to the trader.",
      message_header: "Check the term",
      guidance_level: "warning",
      guidance_location: "results",
      escalate_to_webchat: true,
      filter_prefixes: %w[1201 2309],
      sources: %w[guided_search fpo_search],
      aliases: ["pet food", "animal nutrition"],
      created_at: "2026-04-15T10:30:00Z",
    }
  end

  describe "#as_listing_json" do
    let(:listing_json) do
      {
        id: 123,
        term: "animal feed",
        excluded: false,
        guidance: "Show this guidance message to the trader.",
        guidance_present: true,
        filtering: true,
        behaviour: "Filters to selected short codes",
        escalates: true,
        created_at: "15 April 2026",
      }
    end

    it "returns the agreed listing shape" do
      expect(intercept.as_listing_json).to eq(listing_json)
    end
  end

  describe "#guidance?" do
    it "is true when a message is present" do
      expect(intercept.guidance?).to be(true)
    end

    it "is false when the message is blank" do
      intercept.message = ""

      expect(intercept.guidance?).to be(false)
    end
  end

  describe "#filtering?" do
    it "is true when filter prefixes are present" do
      expect(intercept.filtering?).to be(true)
    end

    it "is false when no prefixes are present" do
      intercept.filter_prefixes = []

      expect(intercept.filtering?).to be(false)
    end
  end

  describe "#aliases_label" do
    it "returns a comma separated label" do
      expect(intercept.aliases_label).to eq("pet food, animal nutrition")
    end

    it "returns a dash when no aliases are present" do
      intercept.aliases = []

      expect(intercept.aliases_label).to eq("-")
    end
  end

  describe "#normalize_serialized_attributes" do
    context "when a message is present" do
      let(:attrs) do
        {
          message: "Show this guidance message to the trader.",
          message_header: "Check the term",
          guidance_level: "warning",
          guidance_location: "results",
          filter_prefixes: %w[1201],
          sources: %w[guided_search],
        }
      end

      let(:default_guidance_metadata) do
        {
          guidance_level: "info",
          guidance_location: "interstitial",
        }
      end

      before do
        intercept.normalize_serialized_attributes(attrs)
      end

      it "defaults guidance metadata when a message is present" do
        expect(attrs).to include(default_guidance_metadata)
      end
    end

    context "when the message is blank" do
      let(:attrs) do
        {
          message: "",
          message_header: "Stale header",
          guidance_level: "warning",
          guidance_location: "results",
          filter_prefixes: %w[1201],
          sources: %w[guided_search],
        }
      end

      let(:cleared_guidance_metadata) do
        {
          message: nil,
          message_header: nil,
          guidance_level: nil,
          guidance_location: nil,
        }
      end

      before do
        intercept.normalize_serialized_attributes(attrs)
      end

      it "clears guidance metadata when the message is blank" do
        expect(attrs).to include(cleared_guidance_metadata)
      end
    end
  end

  describe "#formatted_created_at" do
    it "formats the timestamp as a GOV.UK date" do
      expect(intercept.formatted_created_at).to eq("15 April 2026")
    end

    it "returns Today when created today" do
      intercept.created_at = Date.current.iso8601

      expect(intercept.formatted_created_at).to eq("Today")
    end

    it "returns a dash when created_at is blank" do
      intercept.created_at = nil

      expect(intercept.formatted_created_at).to eq("-")
    end

    it "returns the raw value when created_at cannot be parsed as a date" do
      intercept.created_at = "not a date"

      expect(intercept.formatted_created_at).to eq("not a date")
    end
  end

  describe ".listing" do
    let(:params) { ActionController::Parameters.new(page: "2", q: "gift", ignored: "value") }

    let(:listing) do
      {
        data: [intercept.as_listing_json],
        pagination: {
          page: 1,
          per_page: 20,
          total_count: 1,
          total_pages: 1,
        },
      }
    end

    before do
      allow(described_class).to receive(:all).and_return([described_class.new(attributes)])
    end

    it "passes permitted listing filters to the API" do
      described_class.listing(params)

      expect(described_class).to have_received(:all).with(page: "2", q: "gift")
    end

    it "returns data and default pagination" do
      expect(described_class.listing(params)).to eq(listing)
    end
  end

  describe ".bulk_import" do
    context "when the backend accepts the CSV" do
      let(:csv) { "term,aliases,template\ngift,\"present,gifts\",generic\n" }
      let(:result) { described_class.bulk_import(csv) }

      before do
        stub_api_request("/description_intercepts/bulk_import", :post)
          .with { |request|
            Rack::Utils.parse_nested_query(request.body).dig("data", "attributes", "csv") == csv
          }
          .and_return(
            status: 201,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: { data: { type: "description_intercept_bulk_import", attributes: { created: 1, updated: 2, total: 3 } } }.to_json,
          )
      end

      it "returns a successful result" do
        expect(result).to be_success
      end

      it "returns import counts" do
        expect(result.message).to eq("Imported 3 description intercepts: 1 created, 2 updated.")
      end
    end

    context "when the backend returns validation errors" do
      let(:csv) { "term,aliases,template\ngift,\"present,gifts\",foo\n" }
      let(:result) { described_class.bulk_import(csv) }
      let(:import_errors) { [{ "detail" => "foo and baz are not valid templates" }] }

      before do
        stub_api_request("/description_intercepts/bulk_import", :post)
          .and_return(
            status: 422,
            headers: { "content-type" => "application/json; charset=utf-8" },
            body: { errors: [{ detail: "foo and baz are not valid templates" }] }.to_json,
          )
      end

      it "is not successful" do
        expect(result).not_to be_success
      end

      it "returns grouped backend validation errors" do
        expect(result.errors).to eq(import_errors)
      end
    end
  end

  describe ".find" do
    before do
      stub_api_request("/description_intercepts/123")
        .with(query: hash_including("filter" => { "oid" => "456" }))
        .and_return(
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: {
            data: {
              type: "description_intercept",
              id: "123",
              attributes: attributes.merge(term: "found term"),
            },
            meta: {
              version: {
                current: false,
                oid: 456,
                previous_oid: 455,
                has_previous_version: true,
                latest_event: "update",
              },
            },
          }.to_json,
        )
    end

    it "fetches optional version data using the shared API entity behaviour", :aggregate_failures do
      record = described_class.find("123", oid: "456")

      expect(record.term).to eq("found term")
      expect(record.version_oid).to eq(456)
      expect(record.current?).to be(false)
      expect(record.has_previous_version?).to be(true)
    end
  end
end
