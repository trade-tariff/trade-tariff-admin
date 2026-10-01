RSpec.describe EvaluationGoldQueryItemPolicy do
  subject(:policy) { described_class }

  let(:item) { EvaluationGoldQueryItem.new(resource_id: "atar-600000001", gold_query_set_id: 3) }

  permissions :update?, :destroy? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(policy).to permit(user, item)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(policy).not_to permit(user, item)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(policy).not_to permit(user, item)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(policy).not_to permit(user, item)
    end
  end
end
