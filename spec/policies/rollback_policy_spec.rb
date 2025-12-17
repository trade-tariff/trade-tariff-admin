RSpec.describe RollbackPolicy do
  subject(:rollback_policy) { described_class }

  permissions :access? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(rollback_policy).to permit(user, Rollback.new)
    end

    it "denies access to hmrc admin role" do
      user = create(:user, :hmrc_admin_role)
      expect(rollback_policy).not_to permit(user, Rollback.new)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(rollback_policy).not_to permit(user, Rollback.new)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(rollback_policy).not_to permit(user, Rollback.new)
    end
  end
end
