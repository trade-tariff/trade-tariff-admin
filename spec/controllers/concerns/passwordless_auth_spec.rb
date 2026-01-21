RSpec.describe PasswordlessAuth, type: :controller do
  controller(ApplicationController) do
    include PasswordlessAuth # rubocop:disable RSpec/DescribedClass

    def index
      render plain: "ok"
    end
  end

  before do
    routes.draw { get "passwordless", to: "anonymous#index" }
    allow(TradeTariffAdmin).to receive(:identity_consumer_url).and_return("http://identity.example.com/admin")
    cookies[TradeTariffAdmin.id_token_cookie_name] = "valid-cookie-token"
    allow(VerifyToken).to receive(:new).and_return(verify_token_service)
    session[:token] = SecureRandom.uuid
    create(
      :session,
      expires_at: expires_at,
      token: session[:token],
      id_token: "valid-cookie-token",
    )
  end

  let(:verify_token_service) { instance_double(VerifyToken, call: verify_token_result) }
  let(:verify_token_result) { VerifyToken::Result.new(valid: valid, payload: { "sub" => "user-123" }, reason: reason) }
  let(:valid) { true }
  let(:reason) { nil }
  let(:expires_at) { 1.hour.from_now }

  context "when the session exists and is valid" do
    it "allows the request" do
      get :index

      expect(response).to be_successful
    end
  end

  context "when the session exists but there is no matching id token" do
    before do
      cookies[TradeTariffAdmin.id_token_cookie_name] = "non-matching-cookie-token"
    end

    it "redirects to the identity service when unauthenticated" do
      get :index

      expect(response).to redirect_to("http://identity.example.com/admin")
    end
  end

  context "when the session exists but the session is expired" do
    let(:expires_at) { 1.hour.ago }

    it "redirects to the identity service when unauthenticated" do
      get :index

      expect(response).to redirect_to("http://identity.example.com/admin")
    end
  end

  context "when the session exists but the id_token is invalid" do
    let(:valid) { false }
    let(:reason) { :invalid }

    it "redirects to the identity service when unauthenticated" do
      get :index

      expect(response).to redirect_to("http://identity.example.com/admin")
    end
  end

  context "when the session does not exist" do
    before do
      Session.delete_all
    end

    it "redirects to the identity service when unauthenticated" do
      get :index

      expect(response).to redirect_to("http://identity.example.com/admin")
    end
  end
end
