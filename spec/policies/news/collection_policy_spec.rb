require 'rails_helper'

RSpec.describe News::CollectionPolicy do
  subject(:news_collection_policy) { described_class }

  permissions :edit? do
    it 'grants access to gds editor' do
      expect(news_collection_policy).to permit(User.new(permissions: [User::Permissions::GDS_EDITOR]), News::Collection.new)
    end

    it 'grants access to hmrc editor' do
      expect(news_collection_policy).to permit(User.new(permissions: [User::Permissions::HMRC_EDITOR]), News::Collection.new)
    end

    it 'denies access to regular user with sign in permission' do
      expect(news_collection_policy).not_to permit(User.new(permissions: [User::Permissions::SIGNIN]), News::Collection.new)
    end
  end
end
