RSpec.describe LiveIssuesController, type: :request do
  subject(:rendered_page) { create_user && make_request && response }

  let(:live_issue) { build :live_issue }
  let(:create_user) { create :user, permissions: ['signin', 'HMRC Editor'] }

  describe 'GET #index' do
    before do
      stub_api_request('/live_issues?page=1').and_return \
        jsonapi_response(:live_issue, attributes_for_list(:live_issue, 3))
    end

    let(:make_request) { get live_issues_path }

    it 'returns http success' do
      expect(rendered_page).to have_http_status :success
      expect(rendered_page.body).to include('Manage live issues')
      expect(rendered_page.body).to include(live_issue.title)

    end
  end

  describe 'GET #new' do
    let(:make_request) { get new_live_issue_path }

    it { is_expected.to have_http_status :ok }
  end

  describe 'POST #create' do
    before do
      stub_api_request('/live_issues', :post).to_return create_response
    end

    let :make_request do
      post live_issues_path,
           params: { live_issue: live_issues_params }
    end

    context 'with valid params' do

      let(:live_issues_params) { live_issue.attributes }
      let(:create_response) { webmock_response(:created, live_issue.attributes) }

      it { is_expected.to redirect_to live_issues_path }
    end

    context 'with invalid params' do
      let(:live_issues_params) { live_issue.attributes.without(:title) }
      let(:create_response) { webmock_response(:error, title: "can't be blank'") }

      it { is_expected.to have_http_status :ok }
      it { is_expected.to have_attributes body: /can.+t be blank/ }
    end
  end

  # describe 'GET #edit' do
  #   before do
  #     stub_api_request("/news/items/#{news_item.id}")
  #       .and_return jsonapi_response(:news_item, news_item.attributes)
  #   end

  #   let(:make_request) { get edit_news_item_path(news_item) }

  #   it { is_expected.to have_http_status :success }
  #   it { is_expected.not_to include 'div.current-service' }
  # end

  # describe 'PATCH #update' do
  #   before do
  #     stub_api_request("/news/items/#{news_item.id}")
  #       .and_return jsonapi_response(:news_item, news_item.attributes)

  #     stub_api_request("/news/items/#{news_item.id}", :patch)
  #       .and_return patch_response
  #   end

  #   let :make_request do
  #     patch news_item_path(news_item),
  #           params: { news_item: news_item.attributes.merge(title: new_title) }
  #   end

  #   context 'with valid change' do
  #     let(:new_title) { 'new title' }
  #     let(:patch_response) { webmock_response :updated, "/admin/news/item/#{news_item.id}" }

  #     it { is_expected.to redirect_to news_items_path }
  #   end

  #   context 'with invalid change' do
  #     let(:new_title) { '' }
  #     let(:patch_response) { webmock_response :error, title: "can't be blank" }

  #     it { is_expected.to have_http_status :ok }
  #     it { is_expected.to have_attributes body: /can.+t be blank/ }
  #     it { is_expected.not_to include 'div.current-service' }
  #   end
  # end

  # describe 'DELETE #destroy' do
  #   before do
  #     stub_api_request("/news/items/#{news_item.id}")
  #       .and_return jsonapi_response(:news_item, news_item.attributes)

  #     stub_api_request("/news/items/#{news_item.id}", :delete)
  #       .and_return webmock_response :no_content
  #   end

  #   let(:make_request) { delete news_item_path(news_item) }

  #   it { is_expected.to redirect_to news_items_path }

  #   it 'sets the session' do
  #     rendered_page

  #     expect(
  #       session.dig('flash', 'flashes', 'notice'),
  #     ).to eql('News item removed')
  #   end
  # end

  # context 'when unauthenticated' do
  #   before do
  #     allow(ENV).to receive(:[]).and_call_original
  #     allow(ENV).to receive(:[]).with('GDS_SSO_MOCK_INVALID').and_return 'true'
  #   end

  #   let(:make_request) { get news_items_path }

  #   it { is_expected.to redirect_to '/auth/gds' }
  # end

  # context 'when unauthorised' do
  #   let(:create_user) { create :user, permissions: %w[] }
  #   let(:make_request) { get news_items_path }

  #   it { is_expected.to have_http_status :forbidden }
  #   it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
  # end
end
