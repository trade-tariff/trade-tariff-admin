RSpec.describe DescriptionInterceptPolicy do
  subject(:policy) { described_class }

  let(:intercept) { DescriptionIntercept.new(resource_id: 123, term: "animal feed") }

  permissions :index?, :show?, :update? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(policy).to permit(user, intercept)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(policy).not_to permit(user, intercept)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(policy).not_to permit(user, intercept)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(policy).not_to permit(user, intercept)
    end
  end
end
