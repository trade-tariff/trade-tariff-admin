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
end
