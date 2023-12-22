RSpec.describe ErrorsController, type: :request do
  subject(:rendered) { make_request && response }

  let(:json_response) { JSON.parse(rendered.body) }
  let(:body) { rendered.body }

  describe 'GET /400' do
    let(:make_request) { get '/400' }

    it { expect(body).to include 'Bad request' }
    it { is_expected.to have_http_status(:bad_request) }
  end

  describe 'GET /404' do
    let(:make_request) { get '/404' }

    it { expect(body).to include 'Page not found' }
    it { is_expected.to have_http_status(:not_found) }
  end

  describe 'GET /405' do
    let(:make_request) { get '/405' }

    it { expect(body).to include 'Method not allowed' }
    it { is_expected.to have_http_status(:method_not_allowed) }
  end

  describe 'GET /406' do
    let(:make_request) { get '/406' }

    it { expect(body).to include 'Not acceptable' }
    it { is_expected.to have_http_status(:not_acceptable) }
  end

  describe 'GET /422' do
    let(:make_request) { get '/422' }

    it { expect(body).to include 'Unprocessable entity' }
    it { is_expected.to have_http_status(:unprocessable_entity) }
  end

  describe 'GET /500' do
    let(:make_request) { get '/500' }

    it { expect(body).to include 'We are experiencing technical difficulties' }
    it { is_expected.to have_http_status(:internal_server_error) }
  end

  describe 'GET /501' do
    let(:make_request) { get '/501' }

    it { expect(body).to include 'Not implemented' }
    it { is_expected.to have_http_status(:not_implemented) }
  end
end
