# rubocop:disable RSpec/RepeatedExample
RSpec.describe AdminConfigurationPolicy do
  subject(:policy) { described_class }

  let(:configuration) { AdminConfiguration.new(name: "test") }

  permissions :index?, :show? do
    it "grants superadmin read access" do
      user = create(:user, :superadmin)
      expect(policy).to permit(user, configuration)
    end

    it "grants technical operator read access" do
      user = create(:user, :technical_operator)
      expect(policy).to permit(user, configuration)
    end

    it "grants auditor read access" do
      user = create(:user, :auditor)
      expect(policy).to permit(user, configuration)
    end

    it "denies hmrc admin read access" do
      user = create(:user, :hmrc_admin)
      expect(policy).not_to permit(user, configuration)
    end

    it "denies guest read access" do
      user = create(:user, :guest)
      expect(policy).not_to permit(user, configuration)
    end
  end

  permissions :update? do
    it "grants superadmin update access" do
      user = create(:user, :superadmin)
      expect(policy).to permit(user, configuration)
    end

    it "denies technical operator update access" do
      user = create(:user, :technical_operator)
      expect(policy).not_to permit(user, configuration)
    end

    it "denies auditor update access" do
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
# rubocop:enable RSpec/RepeatedExample
