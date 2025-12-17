# rubocop:disable RSpec/RepeatedExample, RSpec/RepeatedDescription
RSpec.describe UpdatePolicy do
  subject(:update_policy) { described_class }

  let(:update) { Update.new }

  permissions :index?, :show? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(update_policy).to permit(user, update)
    end

    it "grants access to auditor" do
      user = create(:user, :auditor)
      expect(update_policy).to permit(user, update)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(update_policy).not_to permit(user, update)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(update_policy).not_to permit(user, update)
    end
  end

  permissions :download?, :apply_and_clear_cache?, :resend_cds_update_notification? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(update_policy).to permit(user, update)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(update_policy).not_to permit(user, update)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(update_policy).not_to permit(user, update)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(update_policy).not_to permit(user, update)
    end
  end
end
# rubocop:enable RSpec/RepeatedExample, RSpec/RepeatedDescription
