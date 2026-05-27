# rubocop:disable RSpec/RepeatedExample
RSpec.describe CustomsTariff::UpdatePolicy do
  subject(:policy) { described_class }

  let(:update) { CustomsTariff::Update.new(version: "1.31", status: "pending") }

  permissions :index?, :show? do
    it "grants index and show access to technical operator" do
      expect(policy).to permit(create(:user, :technical_operator), update)
    end

    it "grants index and show access to auditor" do
      expect(policy).to permit(create(:user, :auditor), update)
    end

    it "denies index and show access to hmrc admin" do
      expect(policy).not_to permit(create(:user, :hmrc_admin), update)
    end

    it "denies index and show access to guest" do
      expect(policy).not_to permit(create(:user, :guest), update)
    end
  end

  permissions :update? do
    it "grants update access to technical operator" do
      expect(policy).to permit(create(:user, :technical_operator), update)
    end

    it "denies update access to auditor" do
      expect(policy).not_to permit(create(:user, :auditor), update)
    end

    it "denies update access to hmrc admin" do
      expect(policy).not_to permit(create(:user, :hmrc_admin), update)
    end

    it "denies update access to guest" do
      expect(policy).not_to permit(create(:user, :guest), update)
    end
  end
end
# rubocop:enable RSpec/RepeatedExample
