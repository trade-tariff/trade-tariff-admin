RSpec.describe References::EntitySearchesController do
  include_context "with authenticated user"

  describe "GET #index" do
    let(:results) { [] }
    let(:query) { "horses" }

    before do
      allow(References::EntitySearch).to receive(:call).and_return(results)
      get references_search_path, params: { q: query }
    end

    it "returns success" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the search page" do
      expect(response.body).to include("Search tariff entities")
    end

    it "renders browse" do
      expect(response.body).to include("Browse")
    end

    it "renders search" do
      expect(response.body).to include("Search")
    end

    it "marks Search as the current search references tab", :aggregate_failures do
      page = Capybara.string(response.body)

      expect(page).to have_css("nav.app-sub-navigation--nested[aria-label='Search References'] a[aria-current='page']", text: "Search")
      expect(page).to have_css("nav.app-sub-navigation--nested[aria-label='Search References'] a", text: "Browse")
      expect(page).not_to have_css("nav.app-sub-navigation--nested[aria-label='Search References'] a[aria-current='page']", text: "Browse")
    end

    it "searches for the query" do
      expect(References::EntitySearch).to have_received(:call).with(query: "horses")
    end

    context "when no results are found" do
      let(:query) { "does-not-exist" }

      it "returns success" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the empty result" do
        expect(response.body).to include("No matching entities found")
      end

      it "renders the browse hint" do
        expect(response.body).to include("Try using Browse to navigate the hierarchy")
      end
    end
  end
end
