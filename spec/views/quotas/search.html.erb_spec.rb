require 'rails_helper'

RSpec.describe 'quotas/search' do
  subject { render && rendered }

  before { assign :current_quota_definition, quota_definition }
  before { assign :quota_definitions, [] }

  context 'with quota order number origins' do
    let(:quota_definition) { build(:quota_definition, :with_quota_balance_events, :with_quota_order_number_origins) }

    it { is_expected.to have_css 'h1', text: /Quota 051822 - definitions/ }

    it { is_expected.to have_css 'h2', text: 'Core quota data' }

    it { is_expected.to have_css 'div.govuk-accordion' }
  end
end
