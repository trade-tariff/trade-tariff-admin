RSpec.describe EvaluationResultPolicy do
  subject(:policy) { described_class }

  let(:result) { EvaluationResult.new(resource_id: 55, run_id: 9) }

  permissions :index?, :show? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(policy).to permit(user, result)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(policy).not_to permit(user, result)
    end
  end
end
