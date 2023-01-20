require 'rails_helper'

RSpec.describe 'quotas/search' do
  subject { render && rendered }

  before { assign :current_quota_definition, quota_definition }
  before { assign :quota_definitions, [quota_definition, quota_definition] }

  context 'with quota order number origins' do
    let(:quota_definition) { build(:quota_definition, :with_quota_balance_events, :with_quota_order_number_origins) }
    let(:quota_order_number_origin) { quota_definition.quota_order_number_origins.first }

    it { is_expected.to have_css 'h1', text: /Quota 051822 - definitions/ }

    it { is_expected.to have_css 'dd', text: quota_definition.quota_order_number_id }

    it { is_expected.to have_css 'dd', text: quota_definition.quota_type }

    it { is_expected.to have_css 'dd', text: quota_order_number_origin.geographical_area_id }

    it { is_expected.to have_css 'dd', text: quota_order_number_origin.geographical_area_description }

    it { is_expected.to have_css 'dd', text: 'from 1 July 2021 to 1 July 2029' }

    it { is_expected.to have_css 'dd', text: 'From 1 January 2022 to 31 December 2022' }
  end
end
