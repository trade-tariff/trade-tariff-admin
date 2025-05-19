require 'rails_helper'

RSpec.describe News::Item do
  subject(:news_item) { build :news_item, :home_page, :updates_page, :banner }

  it { expect(described_class).to be_uk_only }

  it { is_expected.to respond_to :resource_id }
  it { is_expected.to respond_to :title }
  it { is_expected.to respond_to :content }
  it { is_expected.to respond_to :display_style }
  it { is_expected.to respond_to :show_on_uk }
  it { is_expected.to respond_to :show_on_xi }
  it { is_expected.to respond_to :show_on_home_page }
  it { is_expected.to respond_to :show_on_updates_page }
  it { is_expected.to respond_to :show_on_banner }
  it { is_expected.to respond_to :start_date }
  it { is_expected.to respond_to :end_date }
  it { is_expected.to respond_to :created_at }
  it { is_expected.to respond_to :updated_at }
  it { is_expected.to respond_to :chapters }
  it { is_expected.to respond_to :notify_subscribers }

  it { is_expected.to have_attributes id: news_item.id }
  it { is_expected.to have_attributes title: news_item.title }
  it { is_expected.to have_attributes content: news_item.content }
  it { is_expected.to have_attributes display_style: news_item.display_style }
  it { is_expected.to have_attributes show_on_uk: news_item.show_on_uk }
  it { is_expected.to have_attributes show_on_xi: news_item.show_on_xi }
  it { is_expected.to have_attributes show_on_home_page: news_item.show_on_home_page }
  it { is_expected.to have_attributes show_on_updates_page: news_item.show_on_updates_page }
  it { is_expected.to have_attributes show_on_banner: news_item.show_on_banner }
  it { is_expected.to have_attributes start_date: news_item.start_date }
  it { is_expected.to have_attributes end_date: news_item.end_date }
  it { is_expected.to have_attributes created_at: news_item.created_at }
  it { is_expected.to have_attributes updated_at: news_item.updated_at }
  it { is_expected.to have_attributes chapters: news_item.chapters }
  it { is_expected.to have_attributes notify_subscribers: news_item.notify_subscribers }

  describe '#preview' do
    subject { news_item.preview }

    let(:news_item) { build :news_item, content: '# Hello world', precis: 'precis test' }

    it { is_expected.to eql %(<h1 id="hello-world">Hello world</h1>\n) }

    context 'with service tags' do
      include_context 'with XI service'

      let :news_item do
        build :news_item, content: '[Browse]([[SERVICE_PATH]]/browse)'
      end

      it { is_expected.to eql %(<p><a href="/xi/browse">Browse</a></p>\n) }
    end

    context 'with precis field' do
      subject { news_item.preview 'precis' }

      it { is_expected.to eql "<p>precis test</p>\n" }
    end
  end

  describe '#all' do
    subject { described_class.all }

    before do
      allow(TradeTariffAdmin::ServiceChooser).to \
        receive(:service_choice).and_return service_choice

      stub_api_request('/news/items', backend: 'uk').to_return \
        jsonapi_response(:news_item, attributes_for_list(:news_item, 2))
    end

    context 'with UK service' do
      let(:service_choice) { 'uk' }

      it { is_expected.to have_attributes length: 2 }
    end

    context 'with XI service' do
      let(:service_choice) { 'xi' }

      it { is_expected.to have_attributes length: 2 }
    end
  end

  describe '#collection_ids' do
    subject { described_class.new.collection_ids }

    it { is_expected.to be_instance_of Array }
  end

  describe '#generate_or_normalise_slug!' do
    subject { news_item.generate_or_normalise_slug! }

    context 'when a slug is already present' do
      let(:news_item) { build :news_item, slug: 'foo-bar' }

      it { is_expected.to be_nil }
    end

    context 'when a name is present' do
      let(:news_item) { build :news_item, title: 'Foo Bar', slug: nil }

      it { is_expected.to eq 'foo-bar' }
    end
  end
end
