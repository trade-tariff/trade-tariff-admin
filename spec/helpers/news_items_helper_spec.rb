require "rails_helper"

RSpec.describe NewsItemsHelper do
  describe "#news_item_date" do
    subject { news_item_date date }

    context "without a date" do
      let(:date) { nil }

      it { is_expected.to be_nil }
    end

    context "with a date" do
      let(:date) { Date.yesterday - 6.months }

      it { is_expected.to eql date.strftime("%d/%m/%Y") }
    end

    context "with a datetime" do
      let(:date) { Time.zone.now }

      it { is_expected.to eql date.strftime("%d/%m/%Y") }
    end
  end

  describe "#news_item_bool" do
    subject { news_item_bool value }

    context "with a truthy value" do
      let(:value) { true }

      it { is_expected.to eql "Yes" }
    end

    context "with a falsy value" do
      let(:value) { nil }

      it { is_expected.to eql "No" }
    end
  end

  describe "#format_news_item_pages" do
    subject { format_news_item_pages news_item }

    context "with home page" do
      let(:news_item) { build :news_item, :home_page }

      it { is_expected.to eql "Home" }
    end

    context "with updates page" do
      let(:news_item) { build :news_item, :updates_page }

      it { is_expected.to eql "Updates" }
    end

    context "with banner" do
      let(:news_item) { build :news_item, :banner }

      it { is_expected.to eql "Banner" }
    end

    context "with no pages" do
      let(:news_item) { build :news_item }

      it { is_expected.to eql "No pages" }
    end

    context "with multiple pages" do
      let(:news_item) { build :news_item, :home_page, :updates_page, :banner }

      it { is_expected.to eql "Home, Updates, Banner" }
    end
  end
end
