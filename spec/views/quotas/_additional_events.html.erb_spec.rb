require 'rails_helper'

RSpec.describe 'quotas/_additional_events' do
  subject(:rendered_page) { render_page && rendered }

  let :render_page do
    render 'quotas/additional_events',
           quota_definition:
  end

  context 'with quota critical events' do
    let(:quota_definition) do
      build(:quota_definition, :with_quota_critical_events,
            :without_quota_unsuspension_events,
            :without_quota_exhaustion_events,
            :without_quota_reopening_events,
            :without_quota_unblocking_events)
    end

    let(:critical_event) { quota_definition.quota_critical_events.first }

    it { is_expected.to have_css 'td', text: critical_event.event_date&.to_date&.strftime("%d %b %Y") }

    it { is_expected.to have_css 'td', text: critical_event.event_type }

    it { is_expected.to have_css 'td', text: critical_event.critical_state }
  end

  context 'with quota unsuspension events' do
    let(:quota_definition) do
      build(:quota_definition, :without_quota_critical_events,
            :with_quota_unsuspension_events,
            :without_quota_exhaustion_events,
            :without_quota_reopening_events,
            :without_quota_unblocking_events)
    end

    let(:unsuspension_event) { quota_definition.quota_unsuspension_events.first }

    it { is_expected.to have_css 'td', text: unsuspension_event.event_date&.to_date&.strftime("%d %b %Y") }

    it { is_expected.to have_css 'td', text: unsuspension_event.event_type }
  end
end
