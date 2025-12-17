# rubocop:disable RSpec/RepeatedExample, RSpec/RepeatedDescription
RSpec.describe GreenLanes::CategoryAssessmentPolicy do
  subject(:policy) { described_class }

  let(:category_assessment) { instance_double(GreenLanes::CategoryAssessment) }

  permissions :index?, :show? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(policy).to permit(user, category_assessment)
    end

    it "grants access to auditor" do
      user = create(:user, :auditor)
      expect(policy).to permit(user, category_assessment)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(policy).not_to permit(user, category_assessment)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(policy).not_to permit(user, category_assessment)
    end
  end

  permissions :create?, :update?, :destroy? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(policy).to permit(user, category_assessment)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(policy).not_to permit(user, category_assessment)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(policy).not_to permit(user, category_assessment)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(policy).not_to permit(user, category_assessment)
    end
  end
end
# rubocop:enable RSpec/RepeatedExample, RSpec/RepeatedDescription
