RSpec.describe PagesController do
  include_context "with authenticated user"

  let(:sections) { [] }

  before do
    allow(Section).to receive(:all).and_return(sections)
  end

  describe "GET #index" do
    context "when authorised" do
      it "redirects to customs tariff updates" do
        get dashboard_path

        expect(response).to redirect_to(customs_tariff_updates_path)
      end
    end

    context "when user is an auditor" do
      let(:current_user) { create(:user, :auditor) }

      it "redirects to customs tariff updates" do
        get dashboard_path

        expect(response).to redirect_to(customs_tariff_updates_path)
      end
    end

    context "when user is hmrc_admin" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it "redirects to search references (their default landing page)" do
        get dashboard_path

        expect(response).to redirect_to(references_sections_path)
      end
    end

    context "when user is a guest" do
      let(:current_user) { create(:user, :guest) }

      it "redirects to customs tariff updates" do
        get dashboard_path

        expect(response).to redirect_to(customs_tariff_updates_path)
      end
    end
  end
end
