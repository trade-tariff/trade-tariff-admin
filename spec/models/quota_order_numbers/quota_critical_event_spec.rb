require 'rails_helper'

RSpec.describe QuotaOrderNumbers::QuotaCriticalEvent do
  subject(:quota_critical_event) { build(:quota_critical_event) }

  it 'implements the correct attributes' do
    expect(quota_critical_event).to have_attributes(
      {
        id: quota_critical_event.id,
        critical_state_change_date: quota_critical_event.critical_state_change_date,
        event_type: quota_critical_event.event_type,
        critical_state: quota_critical_event.critical_state,
      },
    )
  end
end
