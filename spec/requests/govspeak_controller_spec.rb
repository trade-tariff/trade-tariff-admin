require 'rails_helper'

describe GovspeakController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:create_user) { create :user, permissions: ['signin', 'HMRC Editor'] }

  describe 'POST #govspeak' do
    let :make_request do
      post govspeak_path(format: :json), params: { govspeak: '# Hello world' }
    end

    it { is_expected.to have_http_status :success }
    it { is_expected.to have_attributes media_type: /json/ }
  end
end
