RSpec.describe "Passwordless authentication", type: :request do
  let(:authenticate_user) { false }
  let!(:current_user) { create(:user, :technical_operator, email: "local@example.test", name: "Prepared local user") }
  let(:decoded_id_token) do
    { "sub" => "local-cognito-account", "email" => "local@example.test", "cognito:groups" => %w[admin], "exp" => 1.hour.from_now.to_i }
  end

  before { cookies[TradeTariffAdmin.id_token_cookie_name] = id_token }

  it "maps the callback to the prepared account without creating another user", :aggregate_failures do
    expect { get "/auth/redirect" }.not_to change(User, :count)
    expect(Session.last.user).to eq(current_user)
    expect(current_user.reload).to have_attributes(uid: "local-cognito-account", name: "Prepared local user", role: User::TECHNICAL_OPERATOR)
  end

  it "permits protected access after the callback" do
    get "/auth/redirect"
    get dashboard_path
    expect(response).to redirect_to(customs_tariff_updates_path)
  end

  context "without a prepared local account" do
    let(:current_user) { nil }

    it "creates neither an account nor a consumer session", :aggregate_failures do
      expect { get "/auth/redirect" }.not_to change(User, :count)
      expect(Session.count).to eq(0)
    end

    it "does not grant protected access" do
      get "/auth/redirect"
      get dashboard_path
      expect(response).to redirect_to(TradeTariffAdmin.identity_consumer_url)
    end
  end

  context "with a token outside the admin group" do
    before do
      allow(VerifyToken).to receive(:new).and_call_original
      allow(TradeTariffAdmin).to receive_messages(identity_cognito_jwks_keys: %w[key], identity_consumer: "admin")
      allow(DecryptToken).to receive(:new).with(id_token).and_return(instance_double(DecryptToken, call: id_token))
      allow(DecodeJwt).to receive(:new).with(id_token).and_return(instance_double(DecodeJwt, call: decoded_id_token.merge("cognito:groups" => %w[other-group])))
    end

    it "creates no consumer session and grants no protected access", :aggregate_failures do
      expect { get "/auth/redirect" }.not_to change(Session, :count)
      get dashboard_path
      expect(response).to redirect_to(TradeTariffAdmin.identity_consumer_url)
    end
  end
end
