RSpec.describe News::ItemPolicy do
  subject(:news_item_policy) { described_class }

  permissions :edit? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(news_item_policy).to permit(user, News::Item.new)
    end

    it "denies access to hmrc admin role" do
      user = create(:user, :hmrc_admin_role)
      expect(news_item_policy).not_to permit(user, News::Item.new)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(news_item_policy).not_to permit(user, News::Item.new)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(news_item_policy).not_to permit(user, News::Item.new)
    end
  end
end
