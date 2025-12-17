RSpec.describe News::CollectionPolicy do
  subject(:news_collection_policy) { described_class }

  permissions :edit? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(news_collection_policy).to permit(user, News::Collection.new)
    end

    it "denies access to hmrc admin role" do
      user = create(:user, :hmrc_admin_role)
      expect(news_collection_policy).not_to permit(user, News::Collection.new)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(news_collection_policy).not_to permit(user, News::Collection.new)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(news_collection_policy).not_to permit(user, News::Collection.new)
    end
  end
end
