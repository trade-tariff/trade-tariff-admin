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

  describe '.govuk_form_for' do
    subject do
      govuk_form_for instance, url: '/ignore' do |f|
        f.govuk_text_field :name
      end
    end

    let :model do
      Class.new do
        include ActiveModel::Model

        attr_accessor :name

        def self.name
          'Person'
        end
      end
    end

    let(:instance) { model.new name: 'Joe' }

    it { is_expected.to have_css 'form .govuk-form-group label' }
  end
end
