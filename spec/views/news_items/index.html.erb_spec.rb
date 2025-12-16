RSpec.describe "news_items/index" do
  subject { render && rendered }

  before { assign :news_items, news_items }

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
