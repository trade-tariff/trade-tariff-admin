require 'rails_helper'

RSpec.describe NewsItemsHelper do
  describe '#news_item_date' do
    subject { news_item_date date }

    context 'without a date' do
      let(:date) { nil }

      it { is_expected.to be_nil }
    end

    context 'with a date' do
      let(:date) { Date.yesterday - 6.months }

      it { is_expected.to eql date.strftime('%d/%m/%Y') }
    end

    context 'with a datetime' do
      let(:date) { Time.zone.now }

      it { is_expected.to eql date.strftime('%d/%m/%Y') }
    end
  end

  describe '#news_item_bool' do
    subject { news_item_bool value }

    context 'with a truthy value' do
      let(:value) { true }

      it { is_expected.to eql 'Yes' }
    end

    context 'with a falsy value' do
      let(:value) { nil }

      it { is_expected.to eql 'No' }
    end
  end
end
