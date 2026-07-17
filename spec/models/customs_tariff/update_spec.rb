RSpec.describe CustomsTariff::Update do
  subject(:update) { described_class.new(attributes) }

  let(:attributes) do
    {
      version: "1.31",
      import_error: nil,
      validity_start_date: "2026-01-01",
      validity_end_date: nil,
      source_url: "https://example.com/document.pdf",
      document_created_on: "2026-01-01",
      created_at: "2026-01-01T00:00:00Z",
      updated_at: "2026-01-01T00:00:00Z",
    }
  end

  describe "#failed?" do
    it "is false when import_error is nil" do
      expect(update).not_to be_failed
    end

    it "is true when import_error is present" do
      update.import_error = "Something went wrong"
      expect(update).to be_failed
    end
  end
end
