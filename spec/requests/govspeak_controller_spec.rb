RSpec.describe GovspeakController do
  subject(:rendered_page) { response }

  include_context "with authenticated user"

  describe "POST #govspeak" do
    before do
      post govspeak_path(format: :json), params: { govspeak: "# Hello world" }
    end

    it { is_expected.to have_http_status :success }
    it { is_expected.to have_attributes media_type: /json/ }

    it "converts markdown to html" do
      expect(rendered_page).to have_attributes body: /h1/
    end

    context "when code reference linkification is requested" do
      before do
        post govspeak_path(format: :json), params: { govspeak: "Chapter 01", linkify_code_references: true }
      end

      it "returns html with goods nomenclature code links" do
        json = JSON.parse(rendered_page.body)

        expect(Capybara.string(json.fetch("govspeak"))).to have_link "Chapter 01", href: "#{TradeTariffAdmin.frontend_host}/search?q=01"
      end
    end
  end

  context "when unauthorised" do
    let(:current_user) { create(:user, :guest) }

    it "returns forbidden" do
      post govspeak_path(format: :json), params: { govspeak: "# Hello world" }

      expect(rendered_page).to have_http_status :forbidden
    end
  end
end
