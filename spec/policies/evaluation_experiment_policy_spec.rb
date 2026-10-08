RSpec.describe EvaluationExperimentPolicy do
  subject(:policy) { described_class }

  let(:experiment) { EvaluationExperiment.new(resource_id: 7, name: "Baseline") }

  permissions :index?, :create?, :destroy? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(policy).to permit(user, experiment)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(policy).not_to permit(user, experiment)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(policy).not_to permit(user, experiment)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(policy).not_to permit(user, experiment)
    end
  end
end
