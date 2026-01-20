# rubocop:disable RSpec/RepeatedExample, RSpec/RepeatedDescription
RSpec.describe ChapterNotePolicy do
  subject(:chapter_note_policy) { described_class }

  let(:chapter_note) { ChapterNote.new }

  permissions :index?, :show? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(chapter_note_policy).to permit(user, chapter_note)
    end

    it "grants access to auditor" do
      user = create(:user, :auditor)
      expect(chapter_note_policy).to permit(user, chapter_note)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(chapter_note_policy).not_to permit(user, chapter_note)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(chapter_note_policy).not_to permit(user, chapter_note)
    end
  end

  permissions :create?, :update?, :destroy? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(chapter_note_policy).to permit(user, chapter_note)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(chapter_note_policy).not_to permit(user, chapter_note)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(chapter_note_policy).not_to permit(user, chapter_note)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(chapter_note_policy).not_to permit(user, chapter_note)
    end
  end
end
# rubocop:enable RSpec/RepeatedExample, RSpec/RepeatedDescription
