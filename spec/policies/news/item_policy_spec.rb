require 'rails_helper'

RSpec.describe News::ItemPolicy do
  subject(:news_item_policy) { described_class }

  permissions :edit? do
    it 'grants access to hmrc admin' do
      expect(news_item_policy).to permit(User.new(permissions: [User::Permissions::HMRC_ADMIN]), News::Item.new)
    end

    it 'grants access to gds editor' do
      expect(news_item_policy).to permit(User.new(permissions: [User::Permissions::GDS_EDITOR]), News::Item.new)
    end

    it 'grants access to hmrc editor' do
      expect(news_item_policy).to permit(User.new(permissions: [User::Permissions::HMRC_EDITOR]), News::Item.new)
    end

    it 'denies access to regular user with sign in permission' do
      expect(news_item_policy).not_to permit(User.new(permissions: [User::Permissions::SIGNIN]), News::Item.new)
    end
  end
end
