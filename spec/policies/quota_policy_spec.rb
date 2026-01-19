# rubocop:disable RSpec/RepeatedExample, RSpec/RepeatedDescription
RSpec.describe QuotaPolicy do
  subject(:quota_policy) { described_class }

  let(:quota) { Quota.new }

  permissions :index?, :show?, :search?, :create? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(quota_policy).to permit(user, quota)
    end

    it "grants access to auditor" do
      user = create(:user, :auditor)
      expect(quota_policy).to permit(user, quota)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(quota_policy).not_to permit(user, quota)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(quota_policy).not_to permit(user, quota)
    end
  end

  permissions :update?, :destroy? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(quota_policy).to permit(user, quota)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(quota_policy).not_to permit(user, quota)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(quota_policy).not_to permit(user, quota)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(quota_policy).not_to permit(user, quota)
    end
  end
end
# rubocop:enable RSpec/RepeatedExample, RSpec/RepeatedDescription
