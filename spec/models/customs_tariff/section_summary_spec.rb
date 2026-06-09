RSpec.describe CustomsTariff::SectionSummary do
  subject(:summary) { described_class.new(attributes) }

  let(:attributes) do
    {
      section_id: 1,
      section_title: "Live animals; animal products",
      position: 1,
      section_note_id: nil,
      section_note_status: "absent",
      chapter_notes_total: 5,
      chapter_notes_changed: 2,
    }
  end

  describe "#chapter_notes_changed?" do
    it "returns true when chapter_notes_changed is greater than zero" do
      expect(summary.chapter_notes_changed?).to be true
    end

    it "returns false when chapter_notes_changed is zero" do
      summary.chapter_notes_changed = 0
      expect(summary.chapter_notes_changed?).to be false
    end
  end

  describe "#chapter_note_summary_label" do
    it "returns 'N changed' when chapters have changed" do
      expect(summary.chapter_note_summary_label).to eq("2 changed")
    end

    it "returns 'Unchanged' when no chapters changed" do
      summary.chapter_notes_changed = 0
      expect(summary.chapter_note_summary_label).to eq("Unchanged")
    end
  end

  describe "#section_note_status_symbol" do
    it "returns the status as a symbol" do
      expect(summary.section_note_status_symbol).to eq(:absent)
    end

    it "returns nil when section_note_status is nil" do
      summary.section_note_status = nil
      expect(summary.section_note_status_symbol).to be_nil
    end
  end
end
