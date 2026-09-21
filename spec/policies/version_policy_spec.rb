RSpec.describe VersionPolicy do
  subject(:policy) { described_class }

  let(:version) { Version.new(item_type: "AdminConfiguration") }

  permissions :index? do
    it "grants superadmin read access" do
      user = create(:user, :superadmin)
      expect(policy).to permit(user, version)
    end

    it "grants technical operator read access" do
      user = create(:user, :technical_operator)
      expect(policy).to permit(user, version)
    end

    it "denies hmrc admin read access" do
      user = create(:user, :hmrc_admin)
      expect(policy).not_to permit(user, version)
    end

    it "denies auditor read access" do
      user = create(:user, :auditor)
      expect(policy).not_to permit(user, version)
    end

    it "denies guest read access" do
      user = create(:user, :guest)
      expect(policy).not_to permit(user, version)
    end
  end

  # A restore writes the record that the version belongs to, so VersionPolicy
  # does not decide it. VersionsController authorises a restore against the
  # policy of that record type. See VersionsController::RESTORE_POLICIES.
  permissions :create?, :update?, :destroy? do
    it "denies access to superadmin" do
      user = create(:user, :superadmin)
      expect(policy).not_to permit(user, version)
    end
  end
end
