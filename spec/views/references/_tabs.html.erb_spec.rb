RSpec.describe "references/_tabs" do
  subject(:rendered_partial) do
    render partial: "references/tabs"
    rendered
  end

  before do
    allow(view).to receive(:current_page?).and_return(false)
    allow(view).to receive(:policy).with(SearchReference).and_return(search_reference_policy)
    allow(view).to receive(:policy).with(References::EntitySearch).and_return(entity_search_policy)
  end

  context "when both browse and search are allowed" do
    let(:search_reference_policy) { instance_double(SearchReferencePolicy, index?: true) }
    let(:entity_search_policy) { instance_double(References::EntitySearchPolicy, index?: true) }

    it "renders both tabs", :aggregate_failures do
      expect(rendered_partial).to include("Browse")
      expect(rendered_partial).to include("Search")
    end
  end

  context "when search is not allowed" do
    let(:search_reference_policy) { instance_double(SearchReferencePolicy, index?: true) }
    let(:entity_search_policy) { instance_double(References::EntitySearchPolicy, index?: false) }

    it "hides search tab", :aggregate_failures do
      expect(rendered_partial).to include("Browse")
      expect(rendered_partial).not_to include(">Search</a>")
    end
  end

  context "when neither tab is allowed" do
    let(:search_reference_policy) { instance_double(SearchReferencePolicy, index?: false) }
    let(:entity_search_policy) { instance_double(References::EntitySearchPolicy, index?: false) }

    it "renders no tabs" do
      expect(rendered_partial).not_to include('class="app-sub-navigation"')
    end
  end
end
