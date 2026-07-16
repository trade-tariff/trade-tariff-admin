RSpec.describe DecodeJwt do
  let(:token) { "encoded-token" }
  let(:payload) { { "sub" => "user-123" } }

  before do
    allow(Rails.logger).to receive_messages(debug: nil, error: nil)
  end

  it "returns nil when no token is supplied" do
    expect(described_class.new(nil).call).to be_nil
  end

  context "when in development" do
    before do
      allow(Rails).to receive(:env).and_return("development".inquiry)
    end

    it "decodes the token without verification" do
      allow(JWT).to receive(:decode).with(token, nil, false).and_return([payload])

      expect(described_class.new(token).call).to eq(payload)
    end

    it "returns nil when decoding has an unexpected result" do
      allow(JWT).to receive(:decode).with(token, nil, false).and_return(nil)

      expect(described_class.new(token).call).to be_nil
    end

    it "raises JWT decoding errors" do
      allow(JWT).to receive(:decode).with(token, nil, false).and_raise(JWT::DecodeError)

      expect { described_class.new(token).call }.to raise_error(JWT::DecodeError)
    end
  end

  context "when outside development" do
    before do
      allow(Rails).to receive(:env).and_return("test".inquiry)
      allow(TradeTariffAdmin).to receive(:identity_cognito_jwks_keys).and_return(keys)
    end

    context "without JWKS keys" do
      let(:keys) { nil }

      it "returns nil" do
        expect(described_class.new(token).call).to be_nil
      end
    end

    context "with JWKS keys" do
      let(:keys) { [{ "kid" => "key-1" }] }
      let(:issuer) { "https://cognito.example.com/pool" }
      let(:config) do
        {
          algorithms: %w[RS256],
          jwks: { keys: },
          iss: issuer,
          verify_iss: true,
        }
      end

      before do
        allow(TradeTariffAdmin).to receive(:identity_cognito_issuer_url).and_return(issuer)
      end

      it "decodes and verifies the token" do
        allow(JWT).to receive(:decode).with(token, nil, true, config).and_return([payload])

        expect(described_class.new(token).call).to eq(payload)
      end
    end
  end
end
