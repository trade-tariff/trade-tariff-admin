RSpec.describe EvaluationSyntheticInputSetPolicy do
  subject(:policy) { described_class }

  let(:synthetic_input_set) { EvaluationSyntheticInputSet.new(resource_id: 3, name: "Baseline") }

  permissions :index?, :create?, :destroy?, :show? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(policy).to permit(user, synthetic_input_set)
    end

    it "grants access to the basic auth user" do
      expect(policy).to permit(User.basic_auth_user!, synthetic_input_set)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(policy).not_to permit(user, synthetic_input_set)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(policy).not_to permit(user, synthetic_input_set)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(policy).not_to permit(user, synthetic_input_set)
    end
  end
end
