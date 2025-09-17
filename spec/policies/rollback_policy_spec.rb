require "rails_helper"

RSpec.describe RollbackPolicy do
  subject(:rollback_policy) { described_class }

  permissions :access? do
    it "grants access to hmrc admin" do
      expect(rollback_policy).to permit(User.new(permissions: [User::Permissions::HMRC_ADMIN]), Rollback.new)
    end

    it "denies access access to gds editor" do
      expect(rollback_policy).not_to permit(User.new(permissions: [User::Permissions::GDS_EDITOR]), Rollback.new)
    end

    it "denies access access to hmrc editor" do
      expect(rollback_policy).not_to permit(User.new(permissions: [User::Permissions::HMRC_EDITOR]), Rollback.new)
    end

    it "denies access to regular user with sign in permission" do
      expect(rollback_policy).not_to permit(User.new(permissions: [User::Permissions::SIGNIN]), Rollback.new)
    end
  end
end
