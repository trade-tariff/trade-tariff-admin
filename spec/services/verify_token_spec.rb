require "rails_helper"

RSpec.describe VerifyToken do
  let(:token) { "encoded-token" }

  it "returns nil when no token is supplied" do
    allow(Rails.logger).to receive(:error)

    expect(described_class.new(nil).call).to be_nil
  end

  it "returns nil when keys are missing outside development" do
    allow(Rails).to receive(:env).and_return("test".inquiry)
    allow(TradeTariffAdmin).to receive(:identity_cognito_jwks_keys).and_return(nil)
    allow(Rails.logger).to receive(:error)

    expect(described_class.new(token).call).to be_nil
  end

  # rubocop:disable RSpec/ExampleLength
  it "returns decoded payload when verification succeeds" do
    payload = { "cognito:groups" => %w[admin], "email" => "user@example.com" }
    allow(TradeTariffAdmin).to receive_messages(identity_consumer: "admin",
                                                identity_cognito_jwks_keys: %w[key])
    allow(DecryptToken).to receive(:new).with(token).and_return(instance_double(DecryptToken, call: token))
    allow(DecodeJwt).to receive(:new).with(token).and_return(instance_double(DecodeJwt, call: payload))

    expect(described_class.new(token).call).to eq(payload)
  end
  # rubocop:enable RSpec/ExampleLength
end
