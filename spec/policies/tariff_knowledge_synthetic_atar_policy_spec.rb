RSpec.describe TariffKnowledgeSyntheticAtarPolicy do
  subject(:policy) { described_class }

  let(:synthetic_atar) { TariffKnowledgeSyntheticAtar.new(resource_id: 12, real_user_search: "plastic box") }

  permissions :index?, :show?, :create?, :update?, :destroy? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(policy).to permit(user, synthetic_atar)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(policy).not_to permit(user, synthetic_atar)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(policy).not_to permit(user, synthetic_atar)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(policy).not_to permit(user, synthetic_atar)
    end
  end
end
