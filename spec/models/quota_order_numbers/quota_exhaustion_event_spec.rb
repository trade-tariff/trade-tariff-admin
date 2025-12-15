RSpec.describe QuotaOrderNumbers::QuotaExhaustionEvent do
  subject(:quota_exhaustion_event) { build(:quota_exhaustion_event) }

  let(:expected_attributes) do
    {
      id: quota_exhaustion_event.id,
      exhaustion_date: quota_exhaustion_event.exhaustion_date,
      event_type: quota_exhaustion_event.event_type,
    }
  end

  it "implements the correct attributes" do
    expect(quota_exhaustion_event).to have_attributes(expected_attributes)
  end
end
