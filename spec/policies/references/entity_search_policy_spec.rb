RSpec.describe References::EntitySearchPolicy do
  subject(:entity_search_policy) { described_class }

  let(:entity_search) { References::EntitySearch }

  permissions :index?, :show? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(entity_search_policy).to permit(user, entity_search)
    end

    it "grants access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(entity_search_policy).to permit(user, entity_search)
    end

    it "grants access to auditor" do
      user = create(:user, :auditor)
      expect(entity_search_policy).to permit(user, entity_search)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(entity_search_policy).not_to permit(user, entity_search)
    end
  end
end
