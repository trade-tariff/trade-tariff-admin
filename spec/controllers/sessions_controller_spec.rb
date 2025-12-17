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

    before do
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: token_payload))
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

      it "redirects to the identity service when the token is invalid", :aggregate_failures do
        allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: nil))
        allow(TradeTariffAdmin).to receive(:identity_consumer_url).and_return("http://identity.example.com/admin")

        get :handle_redirect

        expect(response).to redirect_to("http://identity.example.com/admin")
        expect(Session.count).to be_zero
      end
    end

    context "when the user does not exist" do
      it "redirects to the identity service for sign up", :aggregate_failures do
        allow(TradeTariffAdmin).to receive(:identity_consumer_url).and_return("http://identity.example.com/admin")

        cookies[:id_token] = "encoded-token"

        expect { get :handle_redirect }.not_to change(User, :count)
        expect(Session.count).to be_zero

        expect(response).to redirect_to("http://identity.example.com/admin")
      end
    end
  end
end
