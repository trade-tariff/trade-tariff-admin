require "rails_helper"

RSpec.describe Session do
  describe "#renew?" do
    it "returns true when the token cannot be verified" do
      session = build(:session)
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: nil))

      expect(session.renew?).to be(true)
    end

    it "returns false when the token is valid and not expired" do
      payload = { "exp" => 1.hour.from_now.to_i }
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: payload))
      session = build(:session, expires_at: 1.hour.from_now)

      expect(session.renew?).to be(false)
    end

    it "returns true when the session is expired" do
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: { "exp" => 1.hour.ago.to_i }))
      session = build(:session, expires_at: 1.hour.ago)

      expect(session.renew?).to be(true)
    end
  end
end
