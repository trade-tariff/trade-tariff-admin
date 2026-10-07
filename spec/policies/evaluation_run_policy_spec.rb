RSpec.describe EvaluationRunPolicy do
  subject(:policy) { described_class }

  let(:run) { EvaluationRun.new(resource_id: 9) }

  permissions :create?, :show? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(policy).to permit(user, run)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(policy).not_to permit(user, run)
    end
  end
end
