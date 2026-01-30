# frozen_string_literal: true

RSpec.describe "BasicSessionsController", type: :request do
  before do
    allow(TradeTariffAdmin).to receive_messages(basic_session_authentication?: true, basic_session_password: "test-password")
    Rails.application.reload_routes!
  end

  after do
    Rails.application.reload_routes!
  end

  describe "GET /basic_sessions/new" do
    it "hides the auth banner" do
      get "/basic_sessions/new"
      expect(assigns(:hide_auth_banner)).to be(true)
    end

    it "sets return_url to default_landing_path when not provided" do
      get "/basic_sessions/new"
      expect(assigns(:basic_session).return_url).to eq("/dashboard")
    end
  end

  describe "POST /basic_sessions" do
    context "with invalid password" do
      it "hides the auth banner when re-rendering" do
        post "/basic_sessions", params: { basic_session: { password: "wrong", return_url: "/dashboard" } }
        expect(assigns(:hide_auth_banner)).to be(true)
      end
    end
  end
end
