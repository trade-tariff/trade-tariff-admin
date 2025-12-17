# rubocop:disable RSpec/RepeatedExample, RSpec/RepeatedDescription
RSpec.describe LiveIssuePolicy do
  subject(:live_issue_policy) { described_class }

  let(:live_issue) { LiveIssue.new }

  permissions :index?, :show? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(live_issue_policy).to permit(user, live_issue)
    end

    it "grants access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(live_issue_policy).to permit(user, live_issue)
    end

    it "grants access to auditor" do
      user = create(:user, :auditor)
      expect(live_issue_policy).to permit(user, live_issue)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(live_issue_policy).not_to permit(user, live_issue)
    end
  end

  permissions :create?, :update? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(live_issue_policy).to permit(user, live_issue)
    end

    it "grants access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(live_issue_policy).to permit(user, live_issue)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(live_issue_policy).not_to permit(user, live_issue)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(live_issue_policy).not_to permit(user, live_issue)
    end
  end

  permissions :destroy? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(live_issue_policy).to permit(user, live_issue)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(live_issue_policy).not_to permit(user, live_issue)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(live_issue_policy).not_to permit(user, live_issue)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(live_issue_policy).not_to permit(user, live_issue)
    end
  end
end
# rubocop:enable RSpec/RepeatedExample, RSpec/RepeatedDescription
