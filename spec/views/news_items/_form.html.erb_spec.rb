require 'rails_helper'

describe 'news_items/form' do
  subject(:form) { render_partial && rendered }

  let(:render_partial) { render 'news_items/form', news_item: news_item }

  context 'with new news item' do
    let(:news_item) { NewsItem.new }

    it { is_expected.to have_css 'form input' }
  end

  context 'with valid news item' do
    let(:news_item) { build :news_item }

    it 'populates fields' do
      expect(form).to have_css \
        %(input[type="text"][name$="[title]"][value="#{news_item.title}"])
    end
  end
end
