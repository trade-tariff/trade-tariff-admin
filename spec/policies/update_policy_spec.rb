RSpec.describe UpdatePolicy do
  subject(:tariff_update_policy) { described_class }

  permissions :access? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(tariff_update_policy).to permit(user, Update.new)
    end

    it "denies access to hmrc admin role" do
      user = create(:user, :hmrc_admin_role)
      expect(tariff_update_policy).not_to permit(user, Update.new)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(tariff_update_policy).not_to permit(user, Update.new)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(tariff_update_policy).not_to permit(user, Update.new)
    end
  end
end
