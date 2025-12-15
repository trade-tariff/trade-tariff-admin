RSpec.describe "news_collections/form" do
  subject(:form) { render_partial && rendered }

  let(:render_partial) { render "news_collections/form", news_collection: }

  context "with new news collection" do
    let(:news_collection) { News::Collection.new }

    it { is_expected.to have_css "form input" }
    it { is_expected.to have_css 'input[name="news_collection[name]"]' }
    it { is_expected.to have_css 'input[name="news_collection[priority]"]' }
    it { is_expected.to have_css 'textarea[name="news_collection[description]"]' }
    it { is_expected.to have_css 'input[name="news_collection[published]"]' }
    it { is_expected.to have_css 'input[name="news_collection[subscribable]"]' }
    it { is_expected.to have_css "button", text: "Create Collection" }
  end

  context "with valid news collection" do
    let(:news_collection) { build :news_collection }

    it "populates fields", :aggregate_failures do
      expect(form).to have_css %(input[type="text"][name$="[name]"][value="#{news_collection.name}"])
      expect(form).to have_css %(input[type="text"][name$="[priority]"][value="#{news_collection.priority}"])
      expect(form).to have_css %([id$="news-collection-published-true-field"][checked="checked"])
    end

    it { is_expected.to have_css "textarea", text: news_collection.description }

    it { is_expected.to have_css "button", text: "Update Collection" }
  end
end
