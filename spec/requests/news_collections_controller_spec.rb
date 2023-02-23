require 'rails_helper'

RSpec.describe NewsCollectionsController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:news_collection) { build :news_collection }
  let(:create_user) { create :user, permissions: ['signin', 'HMRC Editor'] }

  describe 'GET #index' do
    before do
      stub_api_request('/news/collections').and_return \
        jsonapi_response :news_collection, attributes_for_list(:news_collection, 3)
    end

    let(:make_request) { get news_collections_path }

    it { is_expected.to have_http_status :success }
  end

  describe 'GET #new' do
    let(:make_request) { get new_news_collection_path }

    it { is_expected.to have_http_status :ok }
  end

  describe 'POST #create' do
    before do
      stub_api_request('admin/news/collections', :post).to_return create_response
    end

    let :make_request do
      post news_collections_path,
           params: { news_collection: news_collection_params }
    end

    context 'with valid collection' do
      let(:news_collection_params) { news_collection.attributes.without(:id) }
      let(:create_response) { webmock_response(:created, news_collection.attributes) }

      it { is_expected.to redirect_to news_collections_path }
    end

    context 'with invalid collection' do
      let(:news_collection_params) { news_collection.attributes.without(:id, :title) }
      let(:create_response) { webmock_response(:error, title: "can't be blank'") }

      it { is_expected.to have_http_status :ok }
      it { is_expected.to have_attributes body: /can.+t be blank/ }
    end
  end

  describe 'GET #edit' do
    before do
      stub_api_request("admin/news/collections/#{news_collection.id}")
        .and_return jsonapi_response(:news_collection, news_collection.attributes)
    end

    let(:make_request) { get edit_news_collection_path(news_collection) }

    it { is_expected.to have_http_status :success }
  end

  describe 'PATCH #update' do
    before do
      stub_api_request("admin/news/collections/#{news_collection.id}")
        .and_return jsonapi_response(:news_collection, news_collection.attributes)

      stub_api_request("admin/news/collections/#{news_collection.id}", :patch)
        .and_return patch_response
    end

    let :make_request do
      patch news_collection_path(news_collection),
            params: { news_collection: news_collection.attributes.merge(name: new_name) }
    end

    context 'with valid change' do
      let(:new_name) { 'new name' }
      let(:patch_response) { webmock_response :updated, "/admin/news/collection/#{news_collection.id}" }

      it { is_expected.to redirect_to news_collections_path }
    end

    context 'with invalid change' do
      let(:new_name) { '' }
      let(:patch_response) { webmock_response :error, name: "can't be blank" }

      it { is_expected.to have_http_status :ok }
      it { is_expected.to have_attributes body: /can.+t be blank/ }
      it { is_expected.not_to include 'div.current-service' }
    end
  end

  context 'when unauthenticated' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('GDS_SSO_MOCK_INVALID').and_return 'true'
    end

    let(:make_request) { get news_collections_path }

    it { is_expected.to redirect_to '/auth/gds' }
  end

  context 'when unauthorised' do
    let(:create_user) { create :user, permissions: %w[] }
    let(:make_request) { get news_collections_path }

    it { is_expected.to have_http_status :forbidden }
    it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
  end
end
