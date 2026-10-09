require "rails_helper"

RSpec.describe SidekiqWebConstraint do
  subject(:constraint) { described_class.new }

  let(:request) do
    ActionDispatch::TestRequest.create.tap do |test_request|
      test_request.session = ActionController::TestSession.new
    end
  end

  describe "#matches? with the none auth strategy" do
    before { allow(TradeTariffAdmin).to receive(:auth_strategy).and_return(:none) }

    it "allows the request" do
      expect(constraint.matches?(request)).to be(true)
    end
  end

  describe "#matches? with the basic auth strategy" do
    before { allow(TradeTariffAdmin).to receive(:auth_strategy).and_return(:basic) }

    it "allows a signed-in basic session" do
      request.session[:authenticated] = true

      expect(constraint.matches?(request)).to be(true)
    end

    it "refuses a request with no basic session" do
      expect(constraint.matches?(request)).to be(false)
    end
  end

  describe "#matches? with the passwordless auth strategy" do
    let(:session_token) { SecureRandom.uuid }
    let(:id_token) { "mock-id-token" }
    let(:user) { create(:user, :technical_operator) }
    let(:valid_token_result) { VerifyToken::Result.new(valid: true, payload: {}, reason: nil) }

    before do
      allow(TradeTariffAdmin).to receive(:auth_strategy).and_return(:passwordless)
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: valid_token_result))
      create(:session, user:, token: session_token, id_token:)
      request.session[:token] = session_token
      request.cookie_jar[TradeTariffAdmin.id_token_cookie_name] = id_token
    end

    it "allows a technical operator" do
      expect(constraint.matches?(request)).to be(true)
    end

    it "allows a superadmin" do
      user.update!(role: User::SUPERADMIN)

      expect(constraint.matches?(request)).to be(true)
    end

    it "refuses an hmrc admin" do
      user.update!(role: User::HMRC_ADMIN)

      expect(constraint.matches?(request)).to be(false)
    end

    it "refuses an auditor" do
      user.update!(role: User::AUDITOR)

      expect(constraint.matches?(request)).to be(false)
    end

    it "refuses a guest" do
      user.update!(role: User::GUEST)

      expect(constraint.matches?(request)).to be(false)
    end

    it "refuses a user whose role changed after an allowed request", :aggregate_failures do
      expect(constraint.matches?(request)).to be(true)

      user.update!(role: User::HMRC_ADMIN)

      expect(constraint.matches?(request)).to be(false)
    end

    it "refuses a request with no session token" do
      request.session.delete(:token)

      expect(constraint.matches?(request)).to be(false)
    end

    it "refuses a session token that does not exist" do
      request.session[:token] = "unknown-token"

      expect(constraint.matches?(request)).to be(false)
    end

    it "refuses an id-token cookie that does not match the session" do
      request.cookie_jar[TradeTariffAdmin.id_token_cookie_name] = "other-id-token"

      expect(constraint.matches?(request)).to be(false)
    end

    it "refuses a request with no id-token cookie" do
      request.cookie_jar.delete(TradeTariffAdmin.id_token_cookie_name)

      expect(constraint.matches?(request)).to be(false)
    end

    it "refuses an expired session" do
      Session.find_by_token(session_token).update!(expires_at: 1.hour.ago)

      expect(constraint.matches?(request)).to be(false)
    end

    it "refuses a session whose id token is not valid" do
      invalid_token_result = VerifyToken::Result.new(valid: false, payload: nil, reason: :expired)
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: invalid_token_result))

      expect(constraint.matches?(request)).to be(false)
    end

    it "logs who made a change request" do
      request.request_method = "POST"
      request.path = "/sidekiq/uk/queues/default/delete"
      allow(Rails.logger).to receive(:info)

      constraint.matches?(request)

      expect(Rails.logger).to have_received(:info).with("[SidekiqWeb] POST /sidekiq/uk/queues/default/delete by user uid=#{user.uid} email=#{user.email}")
    end

    it "does not log a read request" do
      request.request_method = "GET"
      allow(Rails.logger).to receive(:info)

      constraint.matches?(request)

      expect(Rails.logger).not_to have_received(:info).with(/\[SidekiqWeb\]/)
    end

    it "does not log a refused change request" do
      user.update!(role: User::HMRC_ADMIN)
      request.request_method = "POST"
      allow(Rails.logger).to receive(:info)

      constraint.matches?(request)

      expect(Rails.logger).not_to have_received(:info).with(/\[SidekiqWeb\]/)
    end
  end

  describe "#matches? with an unknown auth strategy" do
    before { allow(TradeTariffAdmin).to receive(:auth_strategy).and_return(:something_else) }

    it "refuses the request" do
      expect(constraint.matches?(request)).to be(false)
    end
  end
end
