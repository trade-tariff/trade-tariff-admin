RSpec.describe BasicSessionAuth, type: :controller do
  controller(ApplicationController) do
    include BasicSessionAuth # rubocop:disable RSpec/DescribedClass

    def index
      render plain: current_user&.uid || "anonymous"
    end
  end

  before do
    routes.draw do
      get "basic-session-auth", to: "anonymous#index"
      get "basic_sessions/new", to: "anonymous#index", as: :new_basic_session
    end
    controller.class.include routes.url_helpers
    allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(authentication_enabled)
  end

  let(:authentication_enabled) { true }

  context "when the session is not authenticated" do
    it "redirects to the sign-in page" do
      get :index

      expect(response).to redirect_to(new_basic_session_path(return_url: "/basic-session-auth"))
    end
  end

  context "when the session is authenticated" do
    let(:user) { instance_double(User, uid: "basic_auth_user") }

    before do
      session[:authenticated] = true
      allow(User).to receive(:basic_auth_user!).and_return(user)
    end

    it "uses the basic authentication user" do
      get :index

      expect(response.body).to eq("basic_auth_user")
    end
  end

  context "when basic session authentication is disabled" do
    let(:authentication_enabled) { false }

    it "allows an anonymous request" do
      get :index

      expect(response.body).to eq("anonymous")
    end
  end
end
