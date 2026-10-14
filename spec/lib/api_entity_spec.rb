RSpec.describe ApiEntity do
  subject(:pagination) { api_entity_class.send(:pagination_for, records) }

  let(:api_entity_class) do
    Class.new do
      include ApiEntity
      boolean_attributes :published
    end
  end
  let(:persistence_class) do
    Class.new do
      include ApiEntity

      attributes :title
    end
  end
  let(:collection_path) { "/admin/api_entity_persistence_examples" }
  let(:member_path) { "#{collection_path}/15" }

  before do
    stub_const("ApiEntityPaginationExample", api_entity_class)
    stub_const("ApiEntityPersistenceExample", persistence_class)
  end

  describe ".pagination_for" do
    let(:records) { Kaminari.paginate_array(%w[a b], total_count: 42).page(3).per(2) }

    it "returns pagination metadata from API collections" do
      expect(pagination).to eq(page: 3, per_page: 2, total_count: 42, total_pages: 21)
    end

    context "with plain arrays" do
      let(:records) { %w[a b] }

      it "returns a safe default shape" do
        expect(pagination).to eq(page: 1, per_page: 20, total_count: 2, total_pages: 1)
      end
    end
  end

  describe ".boolean_attributes" do
    it "defines predicate methods for boolean API attributes" do
      expect(api_entity_class.new(published: true).published?).to be(true)
    end

    it "defaults missing boolean API attributes to false" do
      expect(api_entity_class.new.published?).to be(false)
    end
  end

  describe "#save" do
    subject(:saved_record) { entity.save }

    context "when a new record is accepted" do
      let(:entity) { persistence_class.new(title: "Note") }

      before do
        stub_api_request(collection_path, :post).and_return(
          jsonapi_response("api_entity_persistence_example", { "resource_id" => "15", "title" => "Note" }, status: 201),
        )
      end

      it "returns the record" do
        expect(saved_record).to equal(entity)
      end

      it "posts the record" do
        saved_record

        expect(WebMock).to have_requested(:post, %r{#{Regexp.escape(collection_path)}\z})
      end
    end

    context "when a new record is invalid" do
      let(:entity) { persistence_class.new(title: "Note") }

      before do
        stub_api_request(collection_path, :post).and_return(api_error_response(title: "is invalid"))
      end

      it "returns the record" do
        expect(saved_record).to equal(entity)
      end

      it "adds the API error" do
        saved_record

        expect(entity.errors[:title]).to include("Title is invalid")
      end
    end

    context "when a new record request fails" do
      let(:entity) { persistence_class.new(title: "Note") }

      before do
        stub_api_request(collection_path, :post).and_return(
          status: 500,
          headers: { "content-type" => "application/json" },
          body: { errors: [{ detail: "unavailable" }] }.to_json,
        )
      end

      it "propagates the Faraday error" do
        expect { saved_record }.to raise_error(
          an_instance_of(Faraday::ServerError).and(having_attributes(response_status: 500)),
        )
      end
    end

    context "when a persisted record is accepted" do
      let(:entity) { persistence_class.new(resource_id: "15", title: "Note") }

      before do
        stub_api_request(member_path, :patch).and_return(
          jsonapi_response("api_entity_persistence_example", { "resource_id" => "15", "title" => "Note" }),
        )
      end

      it "returns the record" do
        expect(saved_record).to equal(entity)
      end

      it "patches the record" do
        saved_record

        expect(WebMock).to have_requested(:patch, %r{#{Regexp.escape(member_path)}\z})
      end
    end
  end

  describe "#update" do
    subject(:updated_record) { entity.update(title: "Updated") }

    let(:entity) { persistence_class.new(resource_id: "15", title: "Note") }

    before do
      stub_api_request(member_path, :patch).and_return(
        jsonapi_response("api_entity_persistence_example", { "resource_id" => "15", "title" => "Updated" }),
      )
    end

    it "returns the record" do
      expect(updated_record).to equal(entity)
    end

    it "patches the new attributes" do
      updated_record

      expect(WebMock).to have_requested(:patch, member_request_url).with(&method(:updated_title?))
    end

    def member_request_url
      %r{#{Regexp.escape(member_path)}\z}
    end

    def updated_title?(request)
      Rack::Utils.parse_nested_query(request.body).dig("data", "attributes", "title") == "Updated"
    end
  end

  shared_examples "an unwrapped delete failure" do |status, error_class|
    before do
      stub_api_request(member_path, :delete).and_return(
        status:,
        headers: { "content-type" => "application/json" },
        body: { errors: [{ detail: "rejected" }] }.to_json,
      )
    end

    it "raises the Faraday error" do
      expect { delete_response }.to raise_error(
        an_instance_of(error_class).and(having_attributes(response_status: status)),
      )
    end
  end

  shared_examples "a delete contract" do |delete_action|
    subject(:delete_response) { entity.public_send(delete_action) }

    let(:entity) { persistence_class.new(resource_id: "15", title: "Note") }

    context "when the API deletes the record" do
      before do
        stub_api_request(member_path, :delete).and_return(
          status: 200,
          headers: { "content-type" => "application/json" },
          body: { deleted: true }.to_json,
        )
      end

      it "returns the delete response" do
        expect(delete_response).to be_a(Faraday::Response).and(
          have_attributes(status: 200, body: { "deleted" => true }),
        )
      end

      it "sends a delete request" do
        delete_response

        expect(WebMock).to have_requested(:delete, %r{#{Regexp.escape(member_path)}\z})
      end
    end

    context "when the API returns 404" do
      include_examples "an unwrapped delete failure", 404, Faraday::ResourceNotFound
    end

    context "when the API returns 409" do
      include_examples "an unwrapped delete failure", 409, Faraday::ConflictError
    end

    context "when the API returns 422" do
      include_examples "an unwrapped delete failure", 422, Faraday::UnprocessableEntityError
    end

    context "when the API returns 500" do
      include_examples "an unwrapped delete failure", 500, Faraday::ServerError
    end
  end

  describe "#destroy" do
    include_examples "a delete contract", :destroy
  end

  describe "#destroy!" do
    include_examples "a delete contract", :destroy!
  end
end
