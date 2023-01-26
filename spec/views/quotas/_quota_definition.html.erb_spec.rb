require 'rails_helper'

RSpec.describe 'quotas/_quota_definitions' do
  subject(:rendered_page) { render_page && rendered }

  let :render_page do
    render partial: 'quotas/quota_definition', collection: [quota_definition]
  end

  context 'with quota balance events' do
    let(:quota_definition) do
      build(:quota_definition, :with_quota_balance_events,
            :without_quota_critical_events,
            :without_quota_unsuspension_events,
            :without_quota_exhaustion_events,
            :without_quota_reopening_events,
            :without_quota_unblocking_events)
    end

    let(:quota_order_number_origin) { quota_definition.quota_order_number_origins.first }

    it { is_expected.to have_css 'span', text: '1 January 2022 to 31 December 2022' }

    it { is_expected.to have_css 'dd', text: quota_definition.id }

    it { is_expected.to have_css 'dd', text: quota_definition.validity_start_date&.to_date&.to_formatted_s(:govuk) }

    it { is_expected.to have_css 'dd', text: quota_definition.validity_end_date&.to_date&.to_formatted_s(:govuk) }

    it { is_expected.to have_css 'dd', text: "#{quota_definition.initial_volume} #{quota_definition.measurement_unit}" }

    it { is_expected.to have_css 'dd', text: quota_definition.critical_state }

    it { is_expected.to have_css 'dd', text: quota_definition.critical_threshold }

    it { is_expected.to have_css 'h2', text: 'Balance events' }

    it { is_expected.to have_css 'h2', text: 'Additional events' }
  end
end
