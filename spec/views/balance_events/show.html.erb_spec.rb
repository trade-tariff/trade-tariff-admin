require 'rails_helper'

RSpec.describe 'balance_events/show' do
  subject { render && rendered }

  before { assign :current_quota_definition, quota_definition }

  context 'with quota definition' do
    let(:quota_definition) { build(:quota_definition, :with_quota_balance_events, :with_quota_order_number_origins) }

    it { is_expected.to have_css 'h1', text: /Quota 051822/ }

    it { is_expected.to have_css 'p', text: quota_definition.id }

    it { is_expected.to have_css 'p', text: 'from 1 January 2022 to 31 December 2022' }

    it { is_expected.to have_css 'p', text: "#{quota_definition.initial_volume} #{quota_definition.measurement_unit}" }
  end
end
