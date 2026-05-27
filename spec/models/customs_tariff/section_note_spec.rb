RSpec.describe CustomsTariff::SectionNote do
  subject(:section_note) { described_class.new(attributes) }

  let(:attributes) do
    {
      section_id: 1,
      content: "Note content",
      customs_tariff_update_version: "1.31",
      file_diff: nil,
      versions: [],
    }
  end

  describe "#file_diff_status" do
    it "returns :new when file_diff is nil" do
      expect(section_note.file_diff_status).to eq(:new)
    end

    it "returns :unchanged when file_diff is empty" do
      section_note.file_diff = []
      expect(section_note.file_diff_status).to eq(:unchanged)
    end

    it "returns :changed when file_diff has entries" do
      section_note.file_diff = [{ "type" => "change", "value" => "updated text" }]
      expect(section_note.file_diff_status).to eq(:changed)
    end
  end

  describe "#preview" do
    it "returns nil when content is blank" do
      section_note.content = ""
      expect(section_note.preview).to be_nil
    end

    it "passes content through TariffNoteFormatter then GovspeakPreview" do
      formatter = instance_double(TariffNoteFormatter, format: "formatted content")
      renderer = instance_double(GovspeakPreview, render: "<p>formatted content</p>")
      allow(TariffNoteFormatter).to receive(:new).with("Note content").and_return(formatter)
      allow(GovspeakPreview).to receive(:new).with("formatted content").and_return(renderer)

      expect(section_note.preview).to eq("<p>formatted content</p>")
    end
  end

  describe "#version_objects" do
    it "returns an empty array when versions is nil" do
      section_note.versions = nil
      expect(section_note.version_objects).to eq([])
    end

    it "maps each version hash to a Version with resource_id from the id key", :aggregate_failures do
      section_note.versions = [{ "id" => 42, "event" => "update", "object" => {} }]
      version = section_note.version_objects.first

      expect(version).to be_a(Version)
      expect(version.resource_id).to eq(42)
    end
  end
end
