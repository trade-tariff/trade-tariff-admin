require 'rails_helper'

RSpec.describe TariffUpdatePolicy do
  subject(:tariff_update_policy) { described_class }

  permissions :access? do
    it 'grants access to user with full access' do
      expect(tariff_update_policy).to permit(User.new(permissions: [User::Permissions::FULL_ACCESS]), TariffUpdate.new)
    end

    it 'denies access access to gds editor' do
      expect(tariff_update_policy).not_to permit(User.new(permissions: [User::Permissions::GDS_EDITOR]), TariffUpdate.new)
    end

    it 'denies access access to hmrc editor' do
      expect(tariff_update_policy).not_to permit(User.new(permissions: [User::Permissions::HMRC_EDITOR]), TariffUpdate.new)
    end

    it 'denies access to regular user with sign in permission' do
      expect(tariff_update_policy).not_to permit(User.new(permissions: [User::Permissions::SIGNIN]), TariffUpdate.new)
    end
  end
end
