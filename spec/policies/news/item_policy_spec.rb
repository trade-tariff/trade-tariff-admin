# rubocop:disable RSpec/RepeatedExample, RSpec/RepeatedDescription
RSpec.describe News::ItemPolicy do
  subject(:news_item_policy) { described_class }

  let(:news_item) { News::Item.new }

  permissions :index?, :show? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(news_item_policy).to permit(user, news_item)
    end

    it "grants access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(news_item_policy).to permit(user, news_item)
    end

    it "grants access to auditor" do
      user = create(:user, :auditor)
      expect(news_item_policy).to permit(user, news_item)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(news_item_policy).not_to permit(user, news_item)
    end
  end

  permissions :create?, :update? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(news_item_policy).to permit(user, news_item)
    end

    it "grants access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(news_item_policy).to permit(user, news_item)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(news_item_policy).not_to permit(user, news_item)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(news_item_policy).not_to permit(user, news_item)
    end
  end

  permissions :destroy? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(news_item_policy).to permit(user, news_item)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(news_item_policy).not_to permit(user, news_item)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(news_item_policy).not_to permit(user, news_item)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(news_item_policy).not_to permit(user, news_item)
    end
  end
end
# rubocop:enable RSpec/RepeatedExample, RSpec/RepeatedDescription
