require 'rails_helper'

RSpec.describe SectionNotePolicy do
  subject(:section_note_policy) { described_class }

  permissions :edit? do
    it 'grants access to gds editor' do
      expect(section_note_policy).to permit(User.new(permissions: [User::Permissions::GDS_EDITOR]), SectionNote.new)
    end

    it 'grants access to hmrc editor' do
      expect(section_note_policy).to permit(User.new(permissions: [User::Permissions::HMRC_EDITOR]), SectionNote.new)
    end

    it 'denies access to regular user with sign in permission' do
      expect(section_note_policy).not_to permit(User.new(permissions: [User::Permissions::SIGNIN]), SectionNote.new)
    end
  end
end
