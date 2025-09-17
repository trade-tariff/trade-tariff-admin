require "rails_helper"

RSpec.describe QuotaOrderNumbers::QuotaReopeningEvent do
  subject(:quota_reopening_event) { build(:quota_reopening_event) }

  let(:expected_attributes) do
    {
      id: quota_reopening_event.id,
      reopening_date: quota_reopening_event.reopening_date,
      event_type: quota_reopening_event.event_type,
    }
  end

  it "implements the correct attributes" do
    expect(quota_reopening_event).to have_attributes(expected_attributes)
  end
end
