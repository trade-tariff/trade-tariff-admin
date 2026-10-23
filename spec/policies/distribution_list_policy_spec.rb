RSpec.describe DistributionListPolicy do
  subject(:policy) { described_class }

  permissions :index?, :create?, :destroy?, :show? do
    it "grants access to technical operator" do
      expect(policy).to permit(create(:user, :technical_operator), :distribution_list)
    end

    it "grants access to superadmin" do
      expect(policy).to permit(create(:user, :superadmin), :distribution_list)
    end

    %i[hmrc_admin auditor guest].each do |role|
      it "denies access to #{role}" do
        expect(policy).not_to permit(create(:user, role), :distribution_list)
      end
    end

    it "denies access without a user" do
      expect(policy).not_to permit(nil, :distribution_list)
    end
  end
end
