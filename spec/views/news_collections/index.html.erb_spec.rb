RSpec.describe "news_collections/index" do
  subject { render && rendered }

  before do
    assign :news_collections, news_collections
    # Set up Pundit for view specs
    view.extend Pundit::Authorization
    allow(view).to receive(:current_user).and_return(current_user)
  end

  let(:current_user) { create(:user, :technical_operator) }
  let(:news_collections) { [] }

  it { is_expected.to have_css "a", text: "Add a news story collection" }

  context "without news stories" do
    it { is_expected.to have_css ".govuk-inset-text", text: "No News collections" }
  end

  context "with 3 news collections" do
    let(:news_collections) { build_list(:news_collection, 3) }
    let(:news_collection) { news_collections.first }

    it { is_expected.to have_css "td", text: news_collection.id }

    it { is_expected.to have_css "td", text: news_collection.name }

    it { is_expected.to have_css "td", text: news_collection.priority }

    it { is_expected.to have_css "td", text: "Yes" }

    it { is_expected.to have_css "table tbody tr", count: 3 }
  end

  context "when user is an auditor" do
    let(:current_user) { create(:user, :auditor) }
    let(:news_collections) { build_list(:news_collection, 1) }

    it { is_expected.not_to have_link "Edit" }
  end
end
