# rubocop:disable RSpec/ExampleLength
RSpec.describe References::EntitySearchesController do
  include_context "with authenticated user"

  describe "GET #index" do
    let(:results) { [] }

    before do
      allow(References::EntitySearch).to receive(:call).and_return(results)
    end

    it "returns success and renders the search page", :aggregate_failures do
      get references_search_path, params: { q: "horses" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Search tariff entities")
      expect(response.body).to include("Browse")
      expect(response.body).to include("Search")
      expect(References::EntitySearch).to have_received(:call).with(query: "horses")
    end

    context "when no results are found" do
      it "renders the fallback copy", :aggregate_failures do
        get references_search_path, params: { q: "does-not-exist" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No matching entities found")
        expect(response.body).to include("Try using Browse to navigate the hierarchy")
      end
    end
  end
end
# rubocop:enable RSpec/ExampleLength
