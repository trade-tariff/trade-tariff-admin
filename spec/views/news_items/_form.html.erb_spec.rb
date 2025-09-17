require "rails_helper"

RSpec.describe "news_items/form" do
  subject(:form) { render_partial && rendered }

  let(:render_partial) { render "news_items/form", news_item:, collections: }
  let(:collections) { build_pair :news_collection }

  context "with new news item" do
    let(:news_item) { News::Item.new }

    it { is_expected.to have_css "form input" }
    it { is_expected.not_to have_css 'input[name="news_item[slug]"]' }
    it { is_expected.to have_css "fieldset legend", text: /News collections/ }

    context "without collections available" do
      let(:collections) { [] }

      it { is_expected.not_to have_css "fieldset legend", text: /News collections/ }
    end
  end

  context "with valid news item" do
    let(:news_item) { build :news_item }

    it { is_expected.to have_css 'input[name="news_item[slug]"]' }

    it "populates fields" do
      expect(form).to have_css \
        %(input[type="text"][name$="[title]"][value="#{news_item.title}"])
    end
  end
end
