RSpec.describe "news_items/index" do
  subject { render && rendered }

  before do
    assign :news_items, news_items
    # Set up Pundit for view specs
    view.extend Pundit::Authorization
    allow(view).to receive(:current_user).and_return(current_user)
  end

  let(:current_user) { create(:user, :technical_operator) }

  context "without news stories" do
    let(:news_items) { [] }

    it { is_expected.to have_css ".govuk-inset-text", text: "No News stories" }
  end

  context "with 3 news items" do
    let :news_items do
      Kaminari.paginate_array(build_list(:news_item, 3), total_count: 3)
              .page(1)
              .per(10)
    end

    it { is_expected.to have_css "table tbody tr", count: 3 }
  end
end
