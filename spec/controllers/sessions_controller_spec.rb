RSpec.describe SessionsController do
  describe "GET #destroy" do
    let!(:user_session) { create(:session) }

    before do
      session[:token] = user_session.token
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
        expect(response).to redirect_to(root_path)
        expect(Session.last.user.email).to eq("user@example.com")
        expect(Session.last.raw_info).to eq(token_payload)
        expect(Session.last.expires_at.to_i).to eq(Time.zone.at(token_payload["exp"]).to_i)
      end

      # rubocop:disable RSpec/ExampleLength
      it "redirects and clears cookies when token is invalid", :aggregate_failures do
        invalid_result = VerifyToken::Result.new(valid: false, payload: nil, reason: :invalid)
        allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: invalid_result))
        allow(TradeTariffAdmin).to receive_messages(identity_consumer_url: "http://identity.example.com/admin",
                                                    identity_cookie_domain: ".example.com")
        cookies[:refresh_token] = "refresh-token"
        get :handle_redirect
        expect(response).to redirect_to("http://identity.example.com/admin")
        # NOTE: These are positive instructions to delete the cookies and not the current cookie values. Refresh token is not deleted here since we'll reuse it for reauthentication.
        expect(response.cookies).to eq("id_token" => nil)
      end

      it "redirects without clearing cookies when token is expired", :aggregate_failures do
        expired_result = VerifyToken::Result.new(valid: false, payload: nil, reason: :expired)
        allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: expired_result))
        allow(TradeTariffAdmin).to receive(:identity_consumer_url).and_return("http://identity.example.com/admin")
        cookies[:refresh_token] = "refresh-token"
        get :handle_redirect
        expect(response).to redirect_to("http://identity.example.com/admin")
        expect(cookies["id_token"]).to eq("encoded-token")
        expect(cookies["refresh_token"]).to eq("refresh-token")
      end
      # rubocop:enable RSpec/ExampleLength
    end

    context "when the user does not exist" do
      # rubocop:disable RSpec/ExampleLength
      it "redirects to identity service and clears cookies", :aggregate_failures do
        allow(TradeTariffAdmin).to receive_messages(identity_consumer_url: "http://identity.example.com/admin",
                                                    identity_cookie_domain: ".example.com")
        cookies[:id_token] = "encoded-token"
        cookies[:refresh_token] = "refresh-token"
        expect { get :handle_redirect }.not_to change(User, :count)
        expect(response).to redirect_to("http://identity.example.com/admin")

        # NOTE: These are positive instructions to delete the cookies and not the current cookie values. Refresh token is not deleted here since we'll reuse it for reauthentication.
        expect(response.cookies).to eq("id_token" => nil)
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end
end
