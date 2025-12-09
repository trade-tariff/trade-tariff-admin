# rubocop:disable RSpec/MultipleDescribes, RSpec/MultipleExpectations, RSpec/ExampleLength
require "rails_helper"

RSpec.describe "SessionsController", type: :request do
  describe "GET /auth/redirect" do
    let(:authenticate_user) { false }
    let(:extra_session) { {} }

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

    it "creates a session and signs the user in" do
      cookies[:id_token] = "encoded-token"

      expect {
        get "/auth/redirect"
      }.to change(Session, :count).by(1)

      expect(response).to redirect_to(root_path)
      expect(session[:token]).to be_present

      created_session = Session.last
      expect(created_session.user.email).to eq("user@example.com")
      expect(created_session.raw_info).to eq(token_payload)
      expect(created_session.expires_at.to_i).to eq(Time.zone.at(token_payload["exp"]).to_i)
    end

    it "redirects to the identity service when the token is invalid" do
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: nil))
      allow(TradeTariffAdmin).to receive(:identity_consumer_url).and_return("http://identity.example.com/admin")

      get "/auth/redirect"

      expect(response).to redirect_to("http://identity.example.com/admin")
      expect(Session.count).to be_zero
    end
  end
end

RSpec.describe SessionsController, type: :controller do
  describe "GET #destroy" do
    it "clears the stored session" do
      user_session = create(:session)
      session[:token] = user_session.token

      get :destroy

      expect(response).to redirect_to(root_path)
      expect(Session.exists?(id: user_session.id)).to be(false)
      expect(session[:token]).to be_nil
    end
  end
end
# rubocop:enable RSpec/MultipleDescribes, RSpec/MultipleExpectations, RSpec/ExampleLength
