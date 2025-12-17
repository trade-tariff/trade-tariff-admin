RSpec.describe UserPolicy do
  subject(:user_policy) { described_class }

  permissions :edit? do
    context "when using basic auth" do
      before do
        allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(true)
      end

      it "grants access to any user" do
        user = create(:user, :guest)
        target_user = create(:user)
        expect(user_policy).to permit(user, target_user)
      end

      it "grants access even without a user" do
        target_user = create(:user)
        expect(user_policy).to permit(nil, target_user)
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
        user = create(:user, :hmrc_admin_role)
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

  permissions :update? do
    context "when using basic auth" do
      before do
        allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(true)
      end

      it "grants access to any user" do
        user = create(:user, :guest)
        target_user = create(:user)
        expect(user_policy).to permit(user, target_user)
      end

      it "grants access even without a user" do
        target_user = create(:user)
        expect(user_policy).to permit(nil, target_user)
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
        user = create(:user, :hmrc_admin_role)
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

