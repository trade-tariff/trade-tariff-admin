# rubocop:disable RSpec/RepeatedExample, RSpec/RepeatedDescription
RSpec.describe SearchReferencePolicy do
  subject(:search_reference_policy) { described_class }

  let(:search_reference) { SearchReference.new }

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

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(search_reference_policy).not_to permit(user, search_reference)
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
# rubocop:enable RSpec/RepeatedExample, RSpec/RepeatedDescription
