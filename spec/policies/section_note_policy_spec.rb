# rubocop:disable RSpec/RepeatedExample, RSpec/RepeatedDescription
RSpec.describe SectionNotePolicy do
  subject(:section_note_policy) { described_class }

  let(:section_note) { SectionNote.new }

  permissions :index?, :show? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(section_note_policy).to permit(user, section_note)
    end

    it "grants access to auditor" do
      user = create(:user, :auditor)
      expect(section_note_policy).to permit(user, section_note)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(section_note_policy).not_to permit(user, section_note)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(section_note_policy).not_to permit(user, section_note)
    end
  end

  permissions :create?, :update?, :destroy? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(section_note_policy).to permit(user, section_note)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(section_note_policy).not_to permit(user, section_note)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(section_note_policy).not_to permit(user, section_note)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(section_note_policy).not_to permit(user, section_note)
    end
  end
end
# rubocop:enable RSpec/RepeatedExample, RSpec/RepeatedDescription
