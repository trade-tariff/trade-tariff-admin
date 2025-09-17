RSpec.describe ApplicationController, type: :request do
  subject(:do_response) { get("/healthcheck") && response }

  context "when a handled error is raised" do
    before { allow(User).to receive(:first).and_raise(exception) }

    let(:exception) { ActionController::InvalidAuthenticityToken }

    it { is_expected.to have_http_status(:unprocessable_content) }
    it { expect(do_response.body).to include("Unprocessable entity") }
  end
end
