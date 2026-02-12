RSpec.describe Session do
  let(:plain_token) { SecureRandom.uuid }

  describe "validations" do
    subject(:session) { build(:session) }

    it { is_expected.to validate_presence_of(:id_token) }
    it { is_expected.to validate_presence_of(:token) }

    it "validates uniqueness of hashed token" do
      create(:session, token: plain_token)
      duplicate = build(:session, token: plain_token)

      expect(duplicate).not_to be_valid
    end
  end

  describe ".digest" do
    it "returns the hashed token" do
      token = "test1234"

      expect(described_class.digest(token)).to eq(Digest::SHA256.hexdigest(token))
    end
  end

  describe ".find_by_token" do
    context "when session exists" do
      it "finds a session by plain text token" do
        session = create(:session, token: plain_token)

        expect(described_class.find_by_token(plain_token)).to eq(session)
      end
    end

    context "when session does not exist" do
      it "returns nil" do
        expect(described_class.find_by_token("does not exist")).to be_nil
      end
    end
  end

  describe "#token=" do
    it "stores the token as a SHA256 digest" do
      session = build(:session, token: plain_token)

      expect(session.token).to eq(Digest::SHA256.hexdigest(plain_token))
    end

    it "does not store the plain token" do
      session = build(:session, token: plain_token)

      expect(session.token).not_to eq(plain_token)
    end
  end

  describe "#cookie_token_match_for?" do
    subject(:session) { build(:session, id_token: "session_token") }

    context "when the cookie token matches the session's id_token" do
      let(:cookie_token) { "session_token" }

      it { is_expected.to be_cookie_token_match_for(cookie_token) }
    end

    context "when the cookie token does not match the session's id_token" do
      let(:cookie_token) { "different_token" }

      it { is_expected.not_to be_cookie_token_match_for(cookie_token) }
    end

    context "when the cookie token is nil" do
      let(:cookie_token) { nil }

      it { is_expected.not_to be_cookie_token_match_for(cookie_token) }
    end
  end

  describe "#renew?" do
    it "returns true when the token cannot be verified" do
      session = build(:session)
      invalid_result = VerifyToken::Result.new(valid: false, payload: nil, reason: :invalid)
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: invalid_result))

      expect(session.renew?).to be(true)
    end

    it "returns false when the token is valid and not expired" do
      payload = { "exp" => 1.hour.from_now.to_i }
      valid_result = VerifyToken::Result.new(valid: true, payload: payload, reason: nil)
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: valid_result))
      session = build(:session, expires_at: 1.hour.from_now)

      expect(session.renew?).to be(false)
    end

    it "returns true when the session is expired" do
      payload = { "exp" => 1.hour.ago.to_i }
      valid_result = VerifyToken::Result.new(valid: true, payload: payload, reason: nil)
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: valid_result))
      session = build(:session, expires_at: 1.hour.ago)

      expect(session.renew?).to be(true)
    end
  end
end
