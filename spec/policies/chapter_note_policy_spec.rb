RSpec.describe ChapterNotePolicy do
  subject(:chapter_note_policy) { described_class }

  permissions :edit? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(chapter_note_policy).to permit(user, ChapterNote.new)
    end

    it "denies access to hmrc admin role" do
      user = create(:user, :hmrc_admin_role)
      expect(chapter_note_policy).not_to permit(user, ChapterNote.new)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(chapter_note_policy).not_to permit(user, ChapterNote.new)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(chapter_note_policy).not_to permit(user, ChapterNote.new)
    end
  end
end
