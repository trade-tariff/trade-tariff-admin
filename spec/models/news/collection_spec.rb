require 'rails_helper'

RSpec.describe News::Collection do
  subject(:collection) { build :news_collection }

  it { is_expected.to respond_to :id }
  it { is_expected.to respond_to :name }
end