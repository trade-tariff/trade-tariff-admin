RSpec.shared_context "with authenticated user" do # rubocop:disable RSpec/MultipleMemoizedHelpers
  let(:current_user) { create(:user, permissions: ["HMRC Admin"]) }
  let(:session_token) { SecureRandom.uuid }
  let(:authenticate_user) { true }
  let(:user_session) { authenticate_user ? create(:session, user: current_user, token: session_token) : nil }

  let(:decoded_id_token) do
    {
      "sub" => current_user.uid || "user-123",
      "email" => current_user.email,
      "name" => current_user.name,
      "exp" => 1.hour.from_now.to_i,
    }
  end

  let(:verify_result) do
    VerifyToken::Result.new(valid: true, payload: decoded_id_token, reason: nil)
  end

  let(:extra_session) { user_session.present? ? { token: user_session.token } : {} }

  before do |example|
    # Ensure user_session is created before stubbing
    session_instance = user_session

    allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: verify_result))
    allow(TradeTariffAdmin).to receive(:identity_consumer_url).and_return("http://identity.example.com/admin")

    if example.metadata[:type] == :request
      if session_instance
        # Set up session cookie using dev-hub approach
        env = Rack::MockRequest.env_for("/")
        app_config = defined?(app) ? app.env_config : Rails.application.env_config
        env.merge!(app_config)

        setter = proc { |request_env| request_env["rack.session"].merge!(extra_session) }

        ActionDispatch::Session::CookieStore.new(setter, key: "_trade-tariff-admin_app_session").call(env)
        cookies_key_value = env["action_dispatch.cookies"].as_json.first
        cookies[:id_token] = "mock-id-token"
        cookies[cookies_key_value.first] = cookies_key_value.last if cookies_key_value
      end
    elsif example.metadata[:type] == :feature && session_instance
      env = Rack::MockRequest.env_for("/")
      app_config = defined?(app) ? app.env_config : Rails.application.env_config
      env.merge!(app_config)

      setter = proc { |request_env| request_env["rack.session"].merge!(extra_session) }

      ActionDispatch::Session::CookieStore.new(setter, key: "_trade-tariff-admin_app_session").call(env)
      cookies_key_value = env["action_dispatch.cookies"].as_json.first

      rack_session = page.driver.browser.rack_mock_session
      rack_session.cookie_jar[:id_token] = "mock-id-token"
      rack_session.cookie_jar[cookies_key_value.first] = cookies_key_value.last if cookies_key_value
    elsif session_instance
      session[:token] = session_instance.token
    end
  end
end
