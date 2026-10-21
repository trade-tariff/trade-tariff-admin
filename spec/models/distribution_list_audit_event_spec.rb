RSpec.describe DistributionListAuditEvent do
  subject(:event) do
    described_class.new(actor_uid: "operator-1", action: "recipient_added", group_name: "dl-a", recipient_username: "sub-1")
  end

  it { is_expected.to be_valid }

  it "rejects an unknown action" do
    event.action = "something_else"

    expect(event).not_to be_valid
  end

  it "requires a recipient" do
    event.recipient_username = nil

    expect(event).not_to be_valid
  end

  it "cannot be changed once saved" do
    event.save!

    expect { event.update!(group_name: "dl-b") }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  describe ".recent_for" do
    it "returns the newest events for the list first" do
      older = described_class.create!(event.attributes.merge("created_at" => 2.days.ago))
      newer = described_class.create!(event.attributes.merge("created_at" => 1.day.ago))
      described_class.create!(event.attributes.merge("group_name" => "dl-other"))

      expect(described_class.recent_for("dl-a")).to eq([newer, older])
    end
  end
end
