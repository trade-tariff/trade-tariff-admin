require 'rails_helper'

describe GovspeakController do
  subject(:rendered_page) { response }

  before { create :user, permissions: ['signin', 'HMRC Editor'] }

  describe 'POST #govspeak' do
    before do
      post govspeak_path(format: :json), params: { govspeak: '# Hello world' }
    end

    it { is_expected.to have_http_status :success }
    it { is_expected.to have_attributes media_type: /json/ }
  end
end
