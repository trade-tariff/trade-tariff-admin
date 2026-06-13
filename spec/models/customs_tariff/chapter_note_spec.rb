RSpec.describe CustomsTariff::ChapterNote do
  subject(:chapter_note) { described_class.new(attributes) }

  let(:attributes) do
    {
      chapter_id: "01",
      content: "Chapter note content",
      customs_tariff_update_version: "1.31",
      file_diff: nil,
      versions: [],
    }
  end

  describe "#file_diff_status" do
    it "returns :new when file_diff is nil" do
      expect(chapter_note.file_diff_status).to eq(:new)
    end

    it "returns :unchanged when file_diff is empty" do
      chapter_note.file_diff = []
      expect(chapter_note.file_diff_status).to eq(:unchanged)
    end

    it "returns :changed when file_diff has entries" do
      chapter_note.file_diff = [{ "type" => "change", "value" => "updated text" }]
      expect(chapter_note.file_diff_status).to eq(:changed)
    end
  end

  describe "#preview" do
    it "returns nil when content is blank" do
      chapter_note.content = ""
      expect(chapter_note.preview).to be_nil
    end

    it "passes content directly through GovspeakPreview" do
      renderer = instance_double(GovspeakPreview, render: "<p>Chapter note content</p>")
      allow(GovspeakPreview).to receive(:new).with("Chapter note content", linkify_code_references: true).and_return(renderer)

      expect(chapter_note.preview).to eq("<p>Chapter note content</p>")
    end
  end

  describe "#version_objects" do
    it "returns an empty array when versions is nil" do
      chapter_note.versions = nil
      expect(chapter_note.version_objects).to eq([])
    end

    it "maps each version hash to a Version with resource_id from the id key", :aggregate_failures do
      chapter_note.versions = [{ "id" => 42, "event" => "update", "object" => {} }]
      version = chapter_note.version_objects.first

      expect(version).to be_a(Version)
      expect(version.resource_id).to eq(42)
    end
  end

  describe "#has_changeset?" do
    it "returns true when file_diff has changed_fields" do
      chapter_note.file_diff = { "changed_fields" => %w[content], "changes" => {} }
      expect(chapter_note.has_changeset?).to be true
    end

    it "returns false when file_diff is nil" do
      expect(chapter_note.has_changeset?).to be false
    end
  end
end
