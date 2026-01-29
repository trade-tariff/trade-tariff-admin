# frozen_string_literal: true

RSpec.describe HomepageController do
  describe "GET #index" do
    it "renders the landing page without authentication" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it "renders the homepage template" do
      get :index
      expect(response).to render_template(:index)
    end

    it "hides the auth banner" do
      get :index
      expect(assigns(:hide_auth_banner)).to be(true)
    end
  end
end
