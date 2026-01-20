RSpec.describe TradeTariffAdmin do
  def reset_auth_caches!
    described_class.instance_variable_set(:@auth_strategy, nil)
    described_class.instance_variable_set(:@basic_session_password, nil)
    described_class.instance_variable_set(:@identity_consumer_url, nil)
    described_class.instance_variable_set(:@identity_consumer, nil)
    described_class.instance_variable_set(:@identity_cognito_jwks_url, nil)
  end

  around do |example|
    original_auth_strategy = ENV["AUTH_STRATEGY"]
    original_basic_password = ENV["BASIC_PASSWORD"]

    example.run
  ensure
    ENV["AUTH_STRATEGY"] = original_auth_strategy
    ENV["BASIC_PASSWORD"] = original_basic_password
    reset_auth_caches!
  end

  describe ".auth_strategy" do
    it "defaults to passwordless when no env var is set", :aggregate_failures do
      ENV.delete("AUTH_STRATEGY")
      reset_auth_caches!

      expect(described_class.auth_strategy).to eq(:passwordless)
      expect(described_class.authenticate_with_passwordless?).to be(true)
    end

    it "returns passwordless when configured", :aggregate_failures do
      ENV["AUTH_STRATEGY"] = "passwordless"
      reset_auth_caches!

      expect(described_class.auth_strategy).to eq(:passwordless)
      expect(described_class.authenticate_with_passwordless?).to be(true)
    end

    it "returns basic when configured with a password", :aggregate_failures do
      ENV["AUTH_STRATEGY"] = "basic"
      ENV["BASIC_PASSWORD"] = "secret"
      reset_auth_caches!

      expect(described_class.auth_strategy).to eq(:basic)
      expect(described_class.basic_session_authentication?).to be(true)
    end

    it "falls back to passwordless when basic is configured without a password", :aggregate_failures do
      ENV["AUTH_STRATEGY"] = "basic"
      ENV["BASIC_PASSWORD"] = nil
      reset_auth_caches!

      expect(described_class.auth_strategy).to eq(:passwordless)
      expect(described_class.authenticate_with_passwordless?).to be(true)
    end
  end

  describe ".identity_consumer_url" do
    it "builds from base url and consumer" do
      allow(described_class).to receive_messages(identity_base_url: "http://identity.local",
                                                 identity_consumer: "admin")
      reset_auth_caches!

      expect(described_class.identity_consumer_url).to eq("http://identity.local/admin")
    end
  end
end
