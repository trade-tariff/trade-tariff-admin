require 'rails_helper'

RSpec.describe ChapterNotePolicy do
  subject(:chapter_note_policy) { described_class }

  permissions :edit? do
    it 'grants access to gds editor' do
      expect(chapter_note_policy).to permit(User.new(permissions: [User::Permissions::GDS_EDITOR]), ChapterNote.new)
    end

    it 'grants access to hmrc editor' do
      expect(chapter_note_policy).to permit(User.new(permissions: [User::Permissions::HMRC_EDITOR]), ChapterNote.new)
    end

    it 'denies access to regular user with sign in permission' do
      expect(chapter_note_policy).not_to permit(User.new(permissions: [User::Permissions::SIGNIN]), ChapterNote.new)
    end
  end
end
