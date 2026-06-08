RSpec.describe SearchDiagnosticPolicy do
  subject(:policy) { described_class }

  let(:diagnostic) { SearchDiagnostic.new(request_id: "request-123") }

  permissions :index?, :show? do
    it "grants access to technical operator" do
      expect(policy).to permit(create(:user, :technical_operator), diagnostic)
    end

    it "grants access to hmrc admin" do
      expect(policy).to permit(create(:user, :hmrc_admin), diagnostic)
    end

    it "grants access to auditor" do
      expect(policy).to permit(create(:user, :auditor), diagnostic)
    end

    it "denies access to guest user" do
      expect(policy).not_to permit(create(:user, :guest), diagnostic)
    end
  end
end
