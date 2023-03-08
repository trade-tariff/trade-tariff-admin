require 'rails_helper'

RSpec.describe 'quotas/_balance_events' do
  subject(:rendered_page) { render_page && rendered }

  let(:render_page) { render('quotas/balance_events', quota_definition:) }

  context 'with quota balance events' do
    let(:quota_definition) { build(:quota_definition, :with_quota_balance_events) }
    let(:balance_event) { quota_definition.quota_balance_events.first }

    it { is_expected.to have_css 'h2', text: quota_definition.quota_order_number_id }

    it { is_expected.to have_css 'td', text: balance_event.occurrence_timestamp&.to_date&.to_formatted_s(:govuk_short) }

    it { is_expected.to have_css 'td', text: balance_event.last_import_date_in_allocation&.to_date&.to_formatted_s(:govuk_short) }

    it { is_expected.to have_css 'td', text: balance_event.old_balance }

    it { is_expected.to have_css 'td', text: balance_event.imported_amount }

    it { is_expected.to have_css 'td', text: balance_event.new_balance }

    it { is_expected.to have_css 'a', text: 'See the graph of quota balance events' }
  end
end
