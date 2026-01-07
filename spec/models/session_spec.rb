RSpec.describe Session do
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
