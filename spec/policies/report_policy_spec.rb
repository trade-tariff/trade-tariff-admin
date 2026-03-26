RSpec.describe ReportPolicy do
  subject(:report_policy) { described_class }

  let(:report) { Report.new }

  permissions :index?, :show?, :run? do
    it "permits technical operators" do
      expect(report_policy).to permit(create(:user, :technical_operator), report)
    end

    it "denies auditors" do
      expect(report_policy).not_to permit(create(:user, :auditor), report)
    end

    it "denies HMRC admins" do
      expect(report_policy).not_to permit(create(:user, :hmrc_admin), report)
    end

    it "denies guests" do
      expect(report_policy).not_to permit(create(:user, :guest), report)
    end
  end

  permissions :backfill_difference? do
    it "permits technical operators for differences report" do
      expect(report_policy).to permit(create(:user, :technical_operator), Report.new(resource_id: "differences"))
    end

    it "denies technical operators for commodities report" do
      expect(report_policy).not_to permit(create(:user, :technical_operator), Report.new(resource_id: "commodities"))
    end

    it "denies auditors for differences report" do
      expect(report_policy).not_to permit(create(:user, :auditor), Report.new(resource_id: "differences"))
    end
  end
end
