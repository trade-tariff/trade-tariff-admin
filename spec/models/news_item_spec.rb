require 'rails_helper'

describe NewsItem do
  subject(:news_item) { build :news_item }

  it { is_expected.to respond_to :id }
  it { is_expected.to respond_to :title }
  it { is_expected.to respond_to :content }
  it { is_expected.to respond_to :display_style }
  it { is_expected.to respond_to :show_on_uk }
  it { is_expected.to respond_to :show_on_xi }
  it { is_expected.to respond_to :show_on_home_page }
  it { is_expected.to respond_to :show_on_updates_page }
  it { is_expected.to respond_to :start_date }
  it { is_expected.to respond_to :end_date }
  it { is_expected.to respond_to :created_at }
  it { is_expected.to respond_to :updated_at }

  it { is_expected.to have_attributes id: news_item.id }
  it { is_expected.to have_attributes title: news_item.title }
  it { is_expected.to have_attributes content: news_item.content }
  it { is_expected.to have_attributes display_style: news_item.display_style }
  it { is_expected.to have_attributes show_on_uk: news_item.show_on_uk }
  it { is_expected.to have_attributes show_on_xi: news_item.show_on_xi }
  it { is_expected.to have_attributes show_on_home_page: news_item.show_on_home_page }
  it { is_expected.to have_attributes show_on_updates_page: news_item.show_on_updates_page }
  it { is_expected.to have_attributes start_date: news_item.start_date }
  it { is_expected.to have_attributes end_date: news_item.end_date }
  it { is_expected.to have_attributes created_at: news_item.created_at }
  it { is_expected.to have_attributes updated_at: news_item.updated_at }

  describe '#preview' do
    subject { news_item.preview }

    let(:news_item) { build :news_item, content: '# Hello world' }

    it { is_expected.to eql %(<h1 id="hello-world">Hello world</h1>\n) }
  end

  describe '#all' do
    subject { described_class.all }

    before do
      allow(TradeTariffAdmin::ServiceChooser).to \
        receive(:service_choice).and_return service_choice

      stub_request(:get, "#{uk_backend}/admin/news_items").and_return \
        status: 200,
        headers: { 'content-type' => 'application/json; charset=utf-8' },
        body: { data: [], included: [] }.to_json
    end

    let(:uk_backend) { TradeTariffAdmin::ServiceChooser.service_choices['uk'] }

    context 'with UK service' do
      let(:service_choice) { 'uk' }

      it { is_expected.to be_empty }
    end

    context 'with XI service' do
      let(:service_choice) { 'xi' }

      it { is_expected.to be_empty }
    end
  end
end
