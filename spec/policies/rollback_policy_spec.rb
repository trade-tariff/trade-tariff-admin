# rubocop:disable RSpec/RepeatedExample, RSpec/RepeatedDescription
RSpec.describe RollbackPolicy do
  subject(:rollback_policy) { described_class }

  let(:rollback) { Rollback.new }

  permissions :index?, :show? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(rollback_policy).to permit(user, rollback)
    end

    it "grants access to auditor" do
      user = create(:user, :auditor)
      expect(rollback_policy).to permit(user, rollback)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(rollback_policy).not_to permit(user, rollback)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(rollback_policy).not_to permit(user, rollback)
    end
  end

  permissions :create? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(rollback_policy).to permit(user, rollback)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(rollback_policy).not_to permit(user, rollback)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(rollback_policy).not_to permit(user, rollback)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(rollback_policy).not_to permit(user, rollback)
    end
  end
end
# rubocop:enable RSpec/RepeatedExample, RSpec/RepeatedDescription
