RSpec.describe UserPolicy do
  subject(:user_policy) { described_class }

  permissions :update? do
    context "when using basic auth" do
      before do
        allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(true)
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it "grants access to non-guest users" do
        user = create(:user, :technical_operator)
        target_user = create(:user)
        expect(user_policy).to permit(user, target_user)
      end

      it "grants access to hmrc admin users" do
        user = create(:user, :hmrc_admin)
        target_user = create(:user)
        expect(user_policy).to permit(user, target_user)
      end

      it "grants access to auditor users" do
        user = create(:user, :auditor)
        target_user = create(:user)
        expect(user_policy).to permit(user, target_user)
      end

      it "denies access to guest users even with basic auth" do
        user = create(:user, :guest)
        target_user = create(:user)
        expect(user_policy).not_to permit(user, target_user)
      end

      it "denies access in production environment (basic auth override disabled)" do
        allow(Rails.env).to receive(:production?).and_return(true)
        user = create(:user, :hmrc_admin) # Non-technical-operator user
        target_user = create(:user)
        expect(user_policy).not_to permit(user, target_user)
      end

      it "denies access when basic auth is not enabled" do
        allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(false)
        user = create(:user, :technical_operator)
        target_user = create(:user)
        expect(user_policy).to permit(user, target_user) # Still works via technical_operator check
      end
    end

    context "when not using basic auth" do
      before do
        allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(false)
      end

      it "grants access to technical operator" do
        user = create(:user, :technical_operator)
        target_user = create(:user)
        expect(user_policy).to permit(user, target_user)
      end

      it "denies access to hmrc admin" do
        user = create(:user, :hmrc_admin)
        target_user = create(:user)
        expect(user_policy).not_to permit(user, target_user)
      end

      it "denies access to auditor" do
        user = create(:user, :auditor)
        target_user = create(:user)
        expect(user_policy).not_to permit(user, target_user)
      end

      it "denies access to guest user" do
        user = create(:user, :guest)
        target_user = create(:user)
        expect(user_policy).not_to permit(user, target_user)
      end
    end
  end
end
