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
end
