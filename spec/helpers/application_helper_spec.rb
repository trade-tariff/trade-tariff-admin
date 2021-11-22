require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '.govuk_breadcrumbs' do
    subject { govuk_breadcrumbs breadcrumbs }

    let :breadcrumbs do
      {
        'first': '/first',
        'second': '/second',
        'third': '/third',
      }
    end

    it { is_expected.to have_css 'div.govuk-breadcrumbs li.govuk-breadcrumbs__list-item a', count: 3 }
  end
end
