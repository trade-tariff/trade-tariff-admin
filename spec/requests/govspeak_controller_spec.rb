RSpec.describe GovspeakController do
  subject(:rendered_page) { response }

  before { create :user, :technical_operator }

  describe "POST #govspeak" do
    before do
      post govspeak_path(format: :json), params: { govspeak: "# Hello world" }
    end

    it { is_expected.to have_http_status :success }
    it { is_expected.to have_attributes media_type: /json/ }

    it "converts markdown to html" do
      expect(rendered_page).to have_attributes body: /h1/
    end
  end
end
