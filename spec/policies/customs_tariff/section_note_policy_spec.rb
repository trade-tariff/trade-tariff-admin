RSpec.describe CustomsTariff::SectionNotePolicy do
  subject(:policy) { described_class }

  let(:section_note) { CustomsTariff::SectionNote.new(section_id: 1) }

  permissions :edit?, :update? do
    it "grants access to technical operator" do
      expect(policy).to permit(create(:user, :technical_operator), section_note)
    end

    it "denies access to auditor" do
      expect(policy).not_to permit(create(:user, :auditor), section_note)
    end

    it "denies access to hmrc admin" do
      expect(policy).not_to permit(create(:user, :hmrc_admin), section_note)
    end

    it "denies access to guest" do
      expect(policy).not_to permit(create(:user, :guest), section_note)
    end
  end
end
