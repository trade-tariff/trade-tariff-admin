RSpec.describe CustomsTariff::ChapterNotePolicy do
  subject(:policy) { described_class }

  let(:chapter_note) { CustomsTariff::ChapterNote.new(chapter_id: "01") }

  permissions :edit?, :update? do
    it "grants access to technical operator" do
      expect(policy).to permit(create(:user, :technical_operator), chapter_note)
    end

    it "denies access to auditor" do
      expect(policy).not_to permit(create(:user, :auditor), chapter_note)
    end

    it "denies access to hmrc admin" do
      expect(policy).not_to permit(create(:user, :hmrc_admin), chapter_note)
    end

    it "denies access to guest" do
      expect(policy).not_to permit(create(:user, :guest), chapter_note)
    end
  end
end
