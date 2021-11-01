require 'rails_helper'

describe NewsItemsController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:news_item) { build :news_item }
  let(:create_user) { create :user }

  describe 'GET #index' do
    before do
      stub_api_request('/news_items?page=1').and_return \
        jsonapi_response :news_item, attributes_for_list(:news_item, 3)
    end

    let(:make_request) { get news_items_path }

    it { is_expected.to have_http_status :success }
  end

  describe 'GET #new' do
    let(:make_request) { get new_news_item_path }

    it { is_expected.to have_http_status :ok }
  end

  describe 'POST #create' do
    before do
      stub_api_request('/news_items', :post).to_return create_response
    end

    let :make_request do
      post news_items_path,
           params: { news_item: news_item_params }
    end

    let(:create_response) { webmock_response(:created, news_item.attributes) }

    context 'with valid item' do
      let(:news_item_params) { news_item.attributes.without(:id) }

      it { is_expected.to redirect_to news_items_path }
    end

    context 'with invalid item' do
      let(:news_item_params) { news_item.attributes.without(:id, :title) }

      it { is_expected.to have_http_status :ok }
      it { is_expected.to have_attributes body: /can.+t be blank/ }
    end
  end

  describe 'GET #edit' do
    before do
      stub_api_request("/news_items/#{news_item.id}")
        .and_return jsonapi_response(:news_item, news_item.attributes)
    end

    let(:make_request) { get edit_news_item_path(news_item) }

    it { is_expected.to have_http_status :success }
  end

  describe 'PATCH #update' do
    before do
      stub_api_request("/news_items/#{news_item.id}")
        .and_return jsonapi_response(:news_item, news_item.attributes)

      stub_api_request("/news_items/#{news_item.id}", :patch)
        .and_return patch_response
    end

    let :make_request do
      patch news_item_path(news_item),
            params: { news_item: news_item.attributes.merge(title: new_title) }
    end

    let :patch_response do
      webmock_response :updated, "/admin/news_item/#{news_item.id}"
    end

    context 'with valid change' do
      let(:new_title) { 'new title' }

      it { is_expected.to redirect_to news_items_path }
    end

    context 'with invalid change' do
      let(:new_title) { '' }

      it { is_expected.to have_http_status :ok }
      it { is_expected.to have_attributes body: /can.+t be blank/ }
    end
  end

  describe 'DELETE #destroy' do
    before do
      stub_api_request("/news_items/#{news_item.id}")
        .and_return jsonapi_response(:news_item, news_item.attributes)

      stub_api_request("/news_items/#{news_item.id}", :delete)
        .and_return webmock_response :no_content
    end

    let(:make_request) { delete news_item_path(news_item) }

    it { is_expected.to redirect_to news_items_path }

    it 'sets the session' do
      rendered_page

      expect(
        session.dig('flash', 'flashes', 'notice'),
      ).to eql('News item removed')
    end
  end

  context 'when unauthenticated' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('GDS_SSO_MOCK_INVALID').and_return 'true'
    end

    let(:make_request) { get news_items_path }

    it { is_expected.to redirect_to '/auth/gds' }
  end

  context 'when unauthorised' do
    let(:create_user) { create :user, permissions: %w[] }
    let(:make_request) { get news_items_path }

    xit { is_expected.to have_http_status :success }
    xit { is_expected.to match 'contact your Delivery Manager' }
  end
end
