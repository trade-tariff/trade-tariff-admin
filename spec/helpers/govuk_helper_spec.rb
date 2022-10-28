require 'rails_helper'

RSpec.describe GovukHelper do
  let :model do
    Class.new do
      include ActiveModel::Model

      attr_accessor :name

      validates :name, presence: true

      def self.name
        'Person'
      end

      def preview
        '<p>preview content</p>'.html_safe
      end
    end
  end

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

    let(:instance) { model.new name: 'Joe' }

    it { is_expected.to have_css 'form .govuk-form-group label' }

    context 'with errors' do
      let(:instance) { model.new.tap(&:valid?) }

      it { is_expected.to have_css 'form .govuk-error-summary ul li' }
    end
  end

  describe 'submit_button_label' do
    subject do
      btn = nil
      govuk_form_for(instance, url: '/') { |f| btn = submit_button_label(f) }
      btn
    end

    before { allow(instance).to receive(:persisted?).and_return persisted }

    let(:instance) { model.new }

    context 'when new' do
      let(:persisted) { false }

      it { is_expected.to eql "Create #{model.name}" }
    end

    context 'when saved' do
      let(:persisted) { true }

      it { is_expected.to eql "Update #{model.name}" }
    end
  end

  describe 'submit_and_back_buttons' do
    subject do
      govuk_form_for(model.new, url: '/') do |form|
        submit_and_back_buttons form, back_link
      end
    end

    let(:back_link) { root_path }

    it { is_expected.to have_css 'button.govuk-button[type="submit"]' }
    it { is_expected.to have_link 'Back', href: back_link }
  end

  describe 'govuk_markdown_area' do
    subject do
      govuk_form_for(model.new, url: '/') do |form|
        govuk_markdown_area form, :name
      end
    end

    it { is_expected.to have_css '.govuk-grid-row .govuk-grid-column-one-half', count: 2 }
    it { is_expected.to have_css '.govuk-grid-column-one-half textarea.govuk-textarea' }
    it { is_expected.to have_link 'Markdown guide' }
    it { is_expected.to have_css '.govuk-grid-column-one-half .hott-markdown-preview' }
    it { is_expected.to have_css '.hott-markdown-preview p', text: 'preview content' }
    it { is_expected.to have_css '.hott-markdown-preview[data-preview="govspeak"]' }
    it { is_expected.to have_css '.hott-markdown-preview[data-preview-for="#person-name-field"]' }
  end
end
