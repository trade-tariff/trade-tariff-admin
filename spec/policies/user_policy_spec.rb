RSpec.describe UserPolicy do
  subject(:user_policy) { described_class }

  let(:target_user) { create(:user, :guest) }
  let(:policy) { described_class.new(current_user, target_user) }

  permissions :create?, :destroy? do
    context "when not using basic auth" do
      before do
        allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(false)
      end

      it "grants access to superadmin" do
        user = create(:user, :superadmin)
        expect(user_policy).to permit(user, target_user)
      end

      it "denies access to technical operator" do
        user = create(:user, :technical_operator)
        expect(user_policy).not_to permit(user, target_user)
      end
    end
  end

  permissions :update? do
    context "when using basic auth" do
      before do
        allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(true)
      end

      it "grants access to non-guest users" do
        user = create(:user, :technical_operator)
        expect(user_policy).to permit(user, target_user)
      end

      it "grants access to hmrc admin users" do
        user = create(:user, :hmrc_admin)
        expect(user_policy).to permit(user, target_user)
      end

      it "grants access to auditor users" do
        user = create(:user, :auditor)
        expect(user_policy).to permit(user, target_user)
      end

      it "denies access to guest users even with basic auth" do
        user = create(:user, :guest)
        expect(user_policy).not_to permit(user, target_user)
      end
    end

    context "when not using basic auth" do
      before do
        allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(false)
      end

      it "grants access to superadmin" do
        user = create(:user, :superadmin)
        expect(user_policy).to permit(user, target_user)
      end

      it "grants access to technical operator" do
        user = create(:user, :technical_operator)
        expect(user_policy).to permit(user, target_user)
      end

      it "denies access to hmrc admin" do
        user = create(:user, :hmrc_admin)
        expect(user_policy).not_to permit(user, target_user)
      end

      it "denies access to auditor" do
        user = create(:user, :auditor)
        expect(user_policy).not_to permit(user, target_user)
      end

      it "denies access to guest user" do
        user = create(:user, :guest)
        expect(user_policy).not_to permit(user, target_user)
      end
    end
  end

  describe "#assignable_roles" do
    before do
      allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(basic_auth_enabled)
    end

    let(:basic_auth_enabled) { false }

    context "when the current user is superadmin" do
      let(:current_user) { create(:user, :superadmin) }

      it "returns all roles" do
        expect(policy.assignable_roles).to eq(User::VALID_ROLES)
      end
    end

    context "when the current user is technical operator" do
      let(:current_user) { create(:user, :technical_operator) }

      it "returns technical operator and lower roles" do
        expect(policy.assignable_roles).to eq([User::TECHNICAL_OPERATOR, User::HMRC_ADMIN, User::AUDITOR, User::GUEST])
      end
    end

    context "when the current user is hmrc admin using basic auth" do
      let(:basic_auth_enabled) { true }
      let(:current_user) { create(:user, :hmrc_admin) }

      it "returns hmrc admin and lower roles" do
        expect(policy.assignable_roles).to eq([User::HMRC_ADMIN, User::AUDITOR, User::GUEST])
      end
    end
  end

  describe "#role_option_enabled?" do
    before do
      allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(false)
    end

    let(:current_user) { create(:user, :technical_operator) }

    context "when editing a guest user" do
      it "enables roles at or below the user's ceiling", :aggregate_failures do
        expect(policy.role_option_enabled?(User::TECHNICAL_OPERATOR)).to be(true)
        expect(policy.role_option_enabled?(User::HMRC_ADMIN)).to be(true)
        expect(policy.role_option_enabled?(User::SUPERADMIN)).to be(false)
      end
    end

    context "when editing a superadmin" do
      let(:target_user) { create(:user, :superadmin) }

      it "disables all role options because the role is locked", :aggregate_failures do
        expect(policy.locked_higher_role?).to be(true)
        expect(policy.role_option_enabled?(User::SUPERADMIN)).to be(false)
        expect(policy.role_option_enabled?(User::HMRC_ADMIN)).to be(false)
      end
    end
  end

  describe "#role_submittable?" do
    before do
      allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(basic_auth_enabled)
    end

    let(:basic_auth_enabled) { false }

    context "when the current user is technical operator" do
      let(:current_user) { create(:user, :technical_operator) }

      it "denies escalation to superadmin" do
        expect(policy.role_submittable?(User::SUPERADMIN)).to be(false)
      end
    end

    context "when a technical operator edits an existing superadmin" do
      let(:current_user) { create(:user, :technical_operator) }
      let(:target_user) { create(:user, :superadmin) }

      it "allows preserving the superadmin role" do
        expect(policy.role_submittable?(User::SUPERADMIN)).to be(true)
      end

      it "denies changing the superadmin role" do
        expect(policy.role_submittable?(User::HMRC_ADMIN)).to be(false)
      end
    end

    context "when the current user is superadmin" do
      let(:current_user) { create(:user, :superadmin) }

      it "allows assigning any role" do
        expect(policy.role_submittable?(User::SUPERADMIN)).to be(true)
      end
    end

    context "when the current user is hmrc admin using basic auth" do
      let(:basic_auth_enabled) { true }
      let(:current_user) { create(:user, :hmrc_admin) }

      it "allows assigning hmrc admin" do
        expect(policy.role_submittable?(User::HMRC_ADMIN)).to be(true)
      end

      it "denies assigning technical operator" do
        expect(policy.role_submittable?(User::TECHNICAL_OPERATOR)).to be(false)
      end
    end
  end
end
