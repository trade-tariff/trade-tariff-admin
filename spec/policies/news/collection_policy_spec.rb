# rubocop:disable RSpec/RepeatedExample, RSpec/RepeatedDescription
RSpec.describe News::CollectionPolicy do
  subject(:news_collection_policy) { described_class }

  let(:news_collection) { News::Collection.new }

  permissions :index?, :show? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(news_collection_policy).to permit(user, news_collection)
    end

    it "grants access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(news_collection_policy).to permit(user, news_collection)
    end

    it "grants access to auditor" do
      user = create(:user, :auditor)
      expect(news_collection_policy).to permit(user, news_collection)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(news_collection_policy).not_to permit(user, news_collection)
    end
  end

  permissions :create?, :update? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(news_collection_policy).to permit(user, news_collection)
    end

    it "grants access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(news_collection_policy).to permit(user, news_collection)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(news_collection_policy).not_to permit(user, news_collection)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(news_collection_policy).not_to permit(user, news_collection)
    end
  end

  permissions :destroy? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(news_collection_policy).to permit(user, news_collection)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(news_collection_policy).not_to permit(user, news_collection)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(news_collection_policy).not_to permit(user, news_collection)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(news_collection_policy).not_to permit(user, news_collection)
    end
  end
end
# rubocop:enable RSpec/RepeatedExample, RSpec/RepeatedDescription
