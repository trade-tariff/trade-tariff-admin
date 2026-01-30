RSpec.describe PagesController do
  include_context "with authenticated user"

  let(:sections) { [] }

  before do
    allow(Section).to receive(:all).and_return(sections)
  end

  describe "GET #index" do
    context "when authorised" do
      it "returns success" do
        get dashboard_path

        expect(response).to have_http_status :ok
      end
    end

    context "when user is an auditor" do
      let(:current_user) { create(:user, :auditor) }

      it "returns success" do
        get dashboard_path

        expect(response).to have_http_status :ok
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

      it "is forbidden" do
        get dashboard_path

        expect(response).to have_http_status :forbidden
      end
    end
  end
end
