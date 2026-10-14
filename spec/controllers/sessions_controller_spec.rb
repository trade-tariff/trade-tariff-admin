RSpec.describe SessionsController do
  describe "GET #login" do
    context "when using passwordless authentication" do
      before do
        allow(TradeTariffAdmin).to receive_messages(basic_session_authentication?: false, identity_consumer_url: "http://identity.example.com/admin")
      end

      it "redirects to the identity service" do
        get :login
        expect(response).to redirect_to("http://identity.example.com/admin")
      end
    end

    context "when using basic session authentication" do
      before do
        allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(true)
      end

      it "redirects to the basic session login page" do
        get :login
        expect(response).to redirect_to("/basic_sessions/new")
      end
    end

    context "when using no authentication" do
      before do
        allow(TradeTariffAdmin).to receive_messages(basic_session_authentication?: false,
                                                    no_authentication?: true)
      end

      it "redirects to the default landing page" do
        get :login
        expect(response).to redirect_to(customs_tariff_updates_path)
      end
    end
  end

  describe "GET #destroy" do
    let(:token) { SecureRandom.uuid }
    let!(:user_session) { create(:session, token: token) }

    before do
      session[:token] = token
    end

    it "clears the stored session", :aggregate_failures do
      get :destroy

      expect(response).to redirect_to(root_path)
      expect(Session.exists?(id: user_session.id)).to be(false)
      expect(session[:token]).to be_nil
    end
  end

  describe "GET #handle_redirect" do
    let(:token_payload) do
      {
        "sub" => "user-123",
        "email" => "user@example.com",
        "name" => "User Example",
        "exp" => 1.hour.from_now.to_i,
      }
    end
    let(:valid_result) { VerifyToken::Result.new(valid: true, payload: token_payload, reason: nil) }

    before do
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: valid_result))
    end

    context "when the user exists already" do
      before do
        create(:user, email: "user@example.com")
        cookies[:id_token] = "encoded-token"
      end

      it "creates a session and signs the user in", :aggregate_failures do
        expect { get :handle_redirect }.to change(Session, :count)
        expect(response).to redirect_to(customs_tariff_updates_path)
        expect(Session.last.user.email).to eq("user@example.com")
        expect(Session.last.raw_info).to eq(token_payload)
        expect(Session.last.expires_at.to_i).to eq(Time.zone.at(token_payload["exp"]).to_i)
      end

      it "stores a hashed session token" do
        get :handle_redirect

        plain_token = session[:token]

        expect(Session.last.token).to eq(Session.digest(plain_token))
      end
    end

    context "when the token is invalid" do
      before do
        create(:user, email: "user@example.com")
        cookies[:id_token] = "encoded-token"
        invalid_result = VerifyToken::Result.new(valid: false, payload: nil, reason: :invalid)
        allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: invalid_result))
        allow(TradeTariffAdmin).to receive_messages(identity_consumer_url: "http://identity.example.com/admin",
                                                    identity_cookie_domain: ".example.com")
        cookies[:refresh_token] = "refresh-token"
      end

      it "redirects to the identity service" do
        get :handle_redirect

        expect(response).to redirect_to("http://identity.example.com/admin")
      end

      it "clears the id token cookie" do
        get :handle_redirect

        # NOTE: These are positive instructions to delete the cookies and not the current cookie values. Refresh token is not deleted here since we'll reuse it for reauthentication.
        expect(response.cookies).to eq("id_token" => nil)
      end
    end

    context "when the token is expired" do
      before do
        create(:user, email: "user@example.com")
        cookies[:id_token] = "encoded-token"
        expired_result = VerifyToken::Result.new(valid: false, payload: nil, reason: :expired)
        allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: expired_result))
        allow(TradeTariffAdmin).to receive(:identity_consumer_url).and_return("http://identity.example.com/admin")
        cookies[:refresh_token] = "refresh-token"
      end

      it "redirects to the identity service" do
        get :handle_redirect

        expect(response).to redirect_to("http://identity.example.com/admin")
      end

      it "keeps the id token cookie" do
        get :handle_redirect

        expect(cookies["id_token"]).to eq("encoded-token")
      end

      it "keeps the refresh token cookie" do
        get :handle_redirect

        expect(cookies["refresh_token"]).to eq("refresh-token")
      end
    end

    context "when the user does not exist" do
      before do
        allow(TradeTariffAdmin).to receive_messages(identity_consumer_url: "http://identity.example.com/admin",
                                                    identity_cookie_domain: ".example.com")
        cookies[:id_token] = "encoded-token"
        cookies[:refresh_token] = "refresh-token"
      end

      it "does not create a user" do
        expect { get :handle_redirect }.not_to change(User, :count)
      end

      it "redirects to the landing page" do
        get :handle_redirect

        expect(response).to redirect_to(root_path)
      end

      it "includes an access denied message" do
        get :handle_redirect

        expect(flash[:alert]).to include("You do not have access to the Admin Portal")
      end

      it "clears the id token cookie" do
        get :handle_redirect

        # NOTE: These are positive instructions to delete the cookies and not the current cookie values. Refresh token is not deleted here since we'll reuse it for reauthentication.
        expect(response.cookies).to eq("id_token" => nil)
      end
    end
  end
end
