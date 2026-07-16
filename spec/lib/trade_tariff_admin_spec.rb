RSpec.describe TradeTariffAdmin do
  def reset_memoized_settings!
    %i[
      @auth_strategy
      @base_domain
      @basic_session_password
      @identity_cognito_jwks_url
      @identity_consumer
      @identity_consumer_url
      @identity_cookie_domain
    ].each do |setting|
      described_class.remove_instance_variable(setting) if described_class.instance_variable_defined?(setting)
    end
  end

  around do |example|
    original_environment = ENV.to_h
    reset_memoized_settings!
    example.run
  ensure
    ENV.replace(original_environment)
    reset_memoized_settings!
    Rails.cache.delete("identity_cognito_jwks_keys")
  end

  describe ".revision" do
    it "returns the stripped revision" do
      allow(described_class).to receive(:`).and_return("abc123\n")

      expect(described_class.revision).to eq("abc123")
    end
  end

  describe ".host" do
    subject(:host) { described_class.host }

    context "when ADMIN_HOST is not configured" do
      before { ENV.delete("ADMIN_HOST") }

      it { is_expected.to eq("http://localhost") }
    end
  end

  describe ".production?" do
    subject { described_class.production? }

    context "with the production GOV.UK application domain" do
      before { ENV["GOVUK_APP_DOMAIN"] = "tariff-admin-production.cloudapps.digital" }

      it { is_expected.to be(true) }
    end
  end

  describe ".auth_strategy" do
    before do
      ENV["AUTH_STRATEGY"] = strategy
      ENV["BASIC_PASSWORD"] = password
      reset_memoized_settings!
    end

    let(:password) { nil }

    context "when AUTH_STRATEGY is unknown" do
      let(:strategy) { "unknown" }

      it "falls back to passwordless", :aggregate_failures do
        expect(described_class.auth_strategy).to eq(:passwordless)
        expect(described_class.authenticate_with_passwordless?).to be(true)
      end
    end

    context "when AUTH_STRATEGY is none" do
      let(:strategy) { "NONE" }

      it "uses no authentication", :aggregate_failures do
        expect(described_class.auth_strategy).to eq(:none)
        expect(described_class.no_authentication?).to be(true)
      end
    end

    context "when AUTH_STRATEGY is basic with a password" do
      let(:strategy) { "basic" }
      let(:password) { "secret" }

      it "uses basic authentication", :aggregate_failures do
        expect(described_class.auth_strategy).to eq(:basic)
        expect(described_class.basic_session_authentication?).to be(true)
      end
    end

    context "when AUTH_STRATEGY is basic without a password" do
      let(:strategy) { "basic" }

      it { expect(described_class.auth_strategy).to eq(:passwordless) }
    end
  end

  describe ".identity_base_url" do
    subject(:identity_base_url) { described_class.identity_base_url }

    context "when IDENTITY_BASE_URL is not configured" do
      before { ENV.delete("IDENTITY_BASE_URL") }

      it { is_expected.to eq("http://localhost:3005") }
    end
  end

  describe ".identity_encryption_secret" do
    it "returns the configured secret" do
      ENV["IDENTITY_ENCRYPTION_SECRET"] = "secret"

      expect(described_class.identity_encryption_secret).to eq("secret")
    end
  end

  describe ".identity_consumer" do
    subject(:identity_consumer) { described_class.identity_consumer }

    context "when IDENTITY_CONSUMER is not configured" do
      before { ENV.delete("IDENTITY_CONSUMER") }

      it { is_expected.to eq("admin") }
    end
  end

  describe ".identity_consumer_url" do
    it "builds the URL from the identity base URL and consumer" do
      allow(described_class).to receive_messages(
        identity_base_url: "http://identity.local",
        identity_consumer: "admin",
      )

      expect(described_class.identity_consumer_url).to eq("http://identity.local/admin")
    end
  end

  describe ".identity_cognito_jwks_keys" do
    subject(:identity_cognito_jwks_keys) { described_class.identity_cognito_jwks_keys }

    let(:jwks_url) { "https://cognito.example.com/pool/.well-known/jwks.json" }

    before do
      ENV["IDENTITY_COGNITO_JWKS_URL"] = jwks_url
      reset_memoized_settings!
      allow(Rails.cache).to receive(:fetch).and_yield
    end

    context "without a JWKS URL" do
      before do
        ENV.delete("IDENTITY_COGNITO_JWKS_URL")
        reset_memoized_settings!
      end

      it { is_expected.to be_nil }
    end

    context "with a successful response" do
      before do
        response = instance_double(Faraday::Response, success?: true, body: '{"keys":[{"kid":"key-1"}]}')
        allow(Faraday).to receive(:get).with(jwks_url).and_return(response)
      end

      it { is_expected.to eq([{ "kid" => "key-1" }]) }
    end

    context "with an unsuccessful response" do
      before do
        response = instance_double(Faraday::Response, success?: false, status: 503, body: "unavailable")
        allow(Faraday).to receive(:get).with(jwks_url).and_return(response)
      end

      it { is_expected.to be_nil }
    end

    shared_examples "a failed JWKS request" do |error_class|
      before do
        allow(Faraday).to receive(:get).with(jwks_url).and_raise(error_class, "request failed")
      end

      it { is_expected.to be_nil }
    end

    context "with a connection failure" do
      include_examples "a failed JWKS request", Faraday::ConnectionFailed
    end

    context "with a timeout" do
      include_examples "a failed JWKS request", Faraday::TimeoutError
    end

    context "with a client error" do
      include_examples "a failed JWKS request", Faraday::ClientError
    end

    context "with a server error" do
      include_examples "a failed JWKS request", Faraday::ServerError
    end

    context "with an unexpected error" do
      include_examples "a failed JWKS request", StandardError
    end

    context "with invalid JSON" do
      before do
        response = instance_double(Faraday::Response, success?: true, body: "not-json")
        allow(Faraday).to receive(:get).with(jwks_url).and_return(response)
      end

      it { is_expected.to be_nil }
    end
  end

  describe ".identity_cognito_issuer_url" do
    subject(:identity_cognito_issuer_url) { described_class.identity_cognito_issuer_url }

    context "without a JWKS URL" do
      before { ENV.delete("IDENTITY_COGNITO_JWKS_URL") }

      it { is_expected.to be_nil }
    end

    context "with a JWKS URL" do
      before do
        ENV["IDENTITY_COGNITO_JWKS_URL"] = "https://cognito.example.com/pool/.well-known/jwks.json"
      end

      it { is_expected.to eq("https://cognito.example.com/pool") }
    end
  end

  describe ".identity_cookie_domain" do
    subject(:identity_cookie_domain) { described_class.identity_cookie_domain }

    context "when in production" do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
        allow(described_class).to receive(:base_domain).and_return("example.com")
      end

      it { is_expected.to eq(".example.com") }
    end

    context "when outside production" do
      before { allow(Rails.env).to receive(:production?).and_return(false) }

      it { is_expected.to eq(:all) }
    end
  end

  describe ".base_domain" do
    subject(:base_domain) { described_class.base_domain }

    context "with a hostname" do
      before { ENV["GOVUK_APP_DOMAIN"] = "admin.example.com" }

      it { is_expected.to eq("example.com") }
    end
  end

  describe ".frontend_host" do
    subject(:frontend_host) { described_class.frontend_host }

    context "when in production" do
      before { ENV["ENVIRONMENT"] = "production" }

      it { is_expected.to eq("https://www.trade-tariff.service.gov.uk") }
    end

    context "when in staging" do
      before { ENV["ENVIRONMENT"] = "staging" }

      it { is_expected.to eq("https://staging.trade-tariff.service.gov.uk") }
    end

    context "when in development" do
      before { ENV["ENVIRONMENT"] = "development" }

      it { is_expected.to eq("https://dev.trade-tariff.service.gov.uk") }
    end

    context "when in another environment" do
      before { ENV["ENVIRONMENT"] = "test" }

      it { is_expected.to eq("http://localhost:3001") }
    end
  end

  describe ".reporting_cdn_host" do
    subject(:reporting_cdn_host) { described_class.reporting_cdn_host }

    before { ENV.delete("REPORTING_CDN_HOST") }

    context "when REPORTING_CDN_HOST is configured" do
      before { ENV["REPORTING_CDN_HOST"] = "https://custom.example.com" }

      it { is_expected.to eq("https://custom.example.com") }
    end

    context "when in production" do
      before { ENV["ENVIRONMENT"] = "production" }

      it { is_expected.to eq("https://reporting.trade-tariff.service.gov.uk") }
    end
  end

  describe ".id_token_cookie_name" do
    subject(:id_token_cookie_name) { described_class.id_token_cookie_name }

    context "when outside production" do
      before { ENV["ENVIRONMENT"] = "staging" }

      it { is_expected.to eq(:staging_id_token) }
    end
  end

  describe ".refresh_token_cookie_name" do
    subject(:refresh_token_cookie_name) { described_class.refresh_token_cookie_name }

    context "when in production" do
      before { ENV["ENVIRONMENT"] = "production" }

      it { is_expected.to eq(:refresh_token) }
    end
  end

  describe ".enable_section_chapter_note_versioning?" do
    subject(:section_chapter_note_versioning) do
      described_class.enable_section_chapter_note_versioning?
    end

    before do
      allow(described_class).to receive(:enable_section_chapter_note_versioning?).and_call_original
    end

    context "when in production" do
      before { ENV["ENVIRONMENT"] = "production" }

      it { is_expected.to be(false) }
    end

    context "when using the Northern Ireland service" do
      before do
        ENV["ENVIRONMENT"] = "development"
        allow(TradeTariffAdmin::ServiceChooser).to receive(:xi?).and_return(true)
      end

      it { is_expected.to be(false) }
    end

    context "when using the UK service outside production" do
      before do
        ENV["ENVIRONMENT"] = "development"
        allow(TradeTariffAdmin::ServiceChooser).to receive(:xi?).and_return(false)
      end

      it { is_expected.to be(true) }
    end
  end
end
