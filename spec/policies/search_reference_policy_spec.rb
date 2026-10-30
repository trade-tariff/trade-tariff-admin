RSpec.describe SearchReferencePolicy do
  subject(:search_reference_policy) { described_class }

  let(:search_reference) { SearchReference.new }

  permissions :export? do
    %i[technical_operator superadmin hmrc_admin].each do |role|
      it "grants access to #{role}" do
        expect(search_reference_policy).to permit(build(:user, role), search_reference)
      end
    end

    %i[auditor guest].each do |role|
      it "denies access to #{role}" do
        expect(search_reference_policy).not_to permit(build(:user, role), search_reference)
      end
    end

    permissions :export_ai_labels? do
      it "grants access to superadmin" do
        expect(search_reference_policy).to permit(build(:user, :superadmin), search_reference)
      end

      %i[technical_operator hmrc_admin auditor guest].each do |role|
        it "denies access to #{role}" do
          expect(search_reference_policy).not_to permit(build(:user, role), search_reference)
        end
      end

      it "denies access without a user" do
        expect(search_reference_policy).not_to permit(nil, search_reference)
      end
    end

    it "denies access without a user" do
      expect(search_reference_policy).not_to permit(nil, search_reference)
    end
  end

  permissions :index?, :show? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(search_reference_policy).to permit(user, search_reference)
    end

    it "grants access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(search_reference_policy).to permit(user, search_reference)
    end

    it "grants access to auditor" do
      user = create(:user, :auditor)
      expect(search_reference_policy).to permit(user, search_reference)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(search_reference_policy).not_to permit(user, search_reference)
    end
  end

  permissions :create?, :update? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(search_reference_policy).to permit(user, search_reference)
    end

    it "grants access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(search_reference_policy).to permit(user, search_reference)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(search_reference_policy).not_to permit(user, search_reference)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(search_reference_policy).not_to permit(user, search_reference)
    end
  end

  permissions :destroy? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(search_reference_policy).to permit(user, search_reference)
    end

    it "grants access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(search_reference_policy).to permit(user, search_reference)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(search_reference_policy).not_to permit(user, search_reference)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(search_reference_policy).not_to permit(user, search_reference)
    end
  end
end
