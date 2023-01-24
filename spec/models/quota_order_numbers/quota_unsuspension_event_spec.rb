require 'rails_helper'

RSpec.describe QuotaOrderNumbers::QuotaUnsuspensionEvent do
  subject(:quota_unsuspension_event) { build(:quota_unsuspension_event) }

  it 'implements the correct attributes' do
    expect(quota_unsuspension_event).to have_attributes(
      {
        id: quota_unsuspension_event.id,
        unsuspension_date: quota_unsuspension_event.unsuspension_date,
        event_type: quota_unsuspension_event.event_type,
      },
    )
  end
end
