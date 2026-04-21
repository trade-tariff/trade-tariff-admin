RSpec.describe AdminConfigurationPolicy do
  subject(:policy) { described_class }

  let(:configuration) { AdminConfiguration.new(name: "test") }

  permissions :index?, :show? do
    it "grants access to superadmin" do
      user = create(:user, :superadmin)
      expect(policy).to permit(user, configuration)
    end

    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(policy).to permit(user, configuration)
    end

    it "grants access to auditor" do
      user = create(:user, :auditor)
      expect(policy).to permit(user, configuration)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(policy).not_to permit(user, configuration)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(policy).not_to permit(user, configuration)
    end
  end

  permissions :update? do
    it "grants access to superadmin" do
      user = create(:user, :superadmin)
      expect(policy).to permit(user, configuration)
    end

    it "denies access to technical operator" do
      user = create(:user, :technical_operator)
      expect(policy).not_to permit(user, configuration)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(policy).not_to permit(user, configuration)
    end
  end

  permissions :create?, :destroy? do
    it "denies access to superadmin" do
      user = create(:user, :superadmin)
      expect(policy).not_to permit(user, configuration)
    end
  end
end
