require 'rails_helper'

describe NewsItemsController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:news_item) { build :news_item }
  let(:create_user) { create :user }

  describe 'GET #index' do
    before do
      stub_api_for NewsItem do |stub|
        stub.get '/admin/news_items' do |_env|
          jsonapi_success_response :news_item, attributes_for_list(:news_item, 3)
        end
      end
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
      stub_api_for NewsItem do |stub|
        stub.post('/admin/news_items') { create_response }
      end
    end

    let :make_request do
      post news_items_path,
           params: { news_item: news_item_params }
    end

    context 'with valid item' do
      let(:news_item_params) { news_item.attributes.without(:id) }
      let(:create_response) { api_created_response(news_item.attributes) }

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
      stub_api_for NewsItem do |stub|
        stub.get "/admin/news_items/#{news_item.id}" do |_env|
          jsonapi_success_response :news_item, news_item.attributes
        end
      end
    end

    let(:make_request) { get edit_news_item_path(news_item) }

    it { is_expected.to have_http_status :success }
  end

  describe 'PATCH #update' do
    before do
      stub_api_for NewsItem do |stub|
        stub.get "/admin/news_items/#{news_item.id}" do
          jsonapi_success_response :news_item, news_item.attributes
        end

        stub.patch("/admin/news_items/#{news_item.id}") { patch_response }
      end
    end

    let :make_request do
      patch news_item_path(news_item),
            params: { news_item: news_item.attributes.merge(title: new_title) }
    end

    context 'with valid change' do
      let(:new_title) { 'new title' }

      let :patch_response do
        api_updated_response("/admin/news_item/#{news_item.id}")
      end

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
      stub_api_for NewsItem do |stub|
        stub.get "/admin/news_items/#{news_item.id}" do
          jsonapi_success_response :news_item, news_item.attributes
        end

        stub.delete "/admin/news_items/#{news_item.id}" do
          api_no_content_response
        end
      end
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
