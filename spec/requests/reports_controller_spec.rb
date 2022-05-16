require 'rails_helper'

RSpec.describe ReportsController do
  subject(:rendered_page) { make_request && response }

  before do
    create :user, permissions: %w[signin]
  end

  describe 'GET #index' do
    let(:make_request) { get reports_path }

    it { is_expected.to have_http_status :success }

    it 'contain the report' do
      make_request

      expect(rendered_page.body).to include('Commodities extract')
    end
  end
end
