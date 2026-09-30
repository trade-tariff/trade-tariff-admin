RSpec.describe EvaluationGoldQuerySetPolicy do
  subject(:policy) { described_class }

  let(:gold_query_set) { EvaluationGoldQuerySet.new(resource_id: 3, name: "Baseline") }

  permissions :index?, :show?, :create?, :destroy? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(policy).to permit(user, gold_query_set)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(policy).not_to permit(user, gold_query_set)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(policy).not_to permit(user, gold_query_set)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(policy).not_to permit(user, gold_query_set)
    end
  end
end
