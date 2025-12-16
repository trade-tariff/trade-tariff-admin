RSpec.describe QuotaOrderNumbers::QuotaUnblockingEvent do
  subject(:quota_unblocking_event) { build(:quota_unblocking_event) }

  let(:expected_attributes) do
    {
      id: quota_unblocking_event.id,
      unblocking_date: quota_unblocking_event.unblocking_date,
      event_type: quota_unblocking_event.event_type,
    }
  end

  it "implements the correct attributes" do
    expect(quota_unblocking_event).to have_attributes(expected_attributes)
  end
end
