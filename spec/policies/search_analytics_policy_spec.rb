RSpec.describe SearchAnalyticsPolicy do
  subject(:policy) { described_class }

  let(:analytics) { SearchAnalytics.new(period: "24h", view: "all") }

  permissions :index? do
    it "grants access to technical operator" do
      expect(policy).to permit(create(:user, :technical_operator), analytics)
    end

    it "grants access to hmrc admin" do
      expect(policy).to permit(create(:user, :hmrc_admin), analytics)
    end

    it "grants access to auditor" do
      expect(policy).to permit(create(:user, :auditor), analytics)
    end

    it "denies access to guest user" do
      expect(policy).not_to permit(create(:user, :guest), analytics)
    end
  end
end
