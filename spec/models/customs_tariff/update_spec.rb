RSpec.describe CustomsTariff::Update do
  subject(:update) { described_class.new(attributes) }

  let(:attributes) do
    {
      version: "1.31",
      status: "pending",
      validity_start_date: "2026-01-01",
      validity_end_date: nil,
      source_url: "https://example.com/document.pdf",
      document_created_on: "2026-01-01",
      created_at: "2026-01-01T00:00:00Z",
      updated_at: "2026-01-01T00:00:00Z",
    }
  end

  describe "#pending?" do
    it { is_expected.to be_pending }

    it "is false when status is approved" do
      update.status = "approved"
      expect(update).not_to be_pending
    end
  end

  describe "#approved?" do
    it "is false when status is pending" do
      expect(update).not_to be_approved
    end

    it "is true when status is approved" do
      update.status = "approved"
      expect(update).to be_approved
    end
  end

  describe "#rejected?" do
    it "is false when status is pending" do
      expect(update).not_to be_rejected
    end

    it "is true when status is rejected" do
      update.status = "rejected"
      expect(update).to be_rejected
    end
  end

  describe "#status_tag_colour" do
    it "returns 'blue' for pending" do
      expect(update.status_tag_colour).to eq("blue")
    end

    it "returns 'green' for approved" do
      update.status = "approved"
      expect(update.status_tag_colour).to eq("green")
    end

    it "returns 'red' for rejected" do
      update.status = "rejected"
      expect(update.status_tag_colour).to eq("red")
    end

    it "returns 'grey' for an unknown status" do
      update.status = "unknown_value"
      expect(update.status_tag_colour).to eq("grey")
    end
  end
end
