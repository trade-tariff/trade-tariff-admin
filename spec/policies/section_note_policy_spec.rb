RSpec.describe SectionNotePolicy do
  subject(:section_note_policy) { described_class }

  permissions :edit? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(section_note_policy).to permit(user, SectionNote.new)
    end

    it "denies access to hmrc admin role" do
      user = create(:user, :hmrc_admin_role)
      expect(section_note_policy).not_to permit(user, SectionNote.new)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(section_note_policy).not_to permit(user, SectionNote.new)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(section_note_policy).not_to permit(user, SectionNote.new)
    end
  end
end
