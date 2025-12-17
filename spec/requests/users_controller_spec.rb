RSpec.describe UsersController do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }
  let(:target_user) { create(:user, :guest) }

  describe "GET #index" do
    let(:make_request) { get users_path }

    it { is_expected.to have_http_status :success }
  end

  describe "GET #edit" do
    let(:make_request) { get edit_user_path(target_user) }

    it { is_expected.to have_http_status :success }

    it "displays radio buttons for role selection" do
      rendered_page
      expect(response.body).to include("radio")
      expect(response.body).to include(User::GUEST)
      expect(response.body).to include(User::TECHNICAL_OPERATOR)
      expect(response.body).to include(User::HMRC_ADMIN)
      expect(response.body).to include(User::AUDITOR)
    end

    it "preselects the current role" do
      rendered_page
      expect(response.body).to include("checked")
    end
  end

  describe "PATCH #update" do
    let(:make_request) do
      patch user_path(target_user),
            params: { user: { role: new_role } }
    end

    context "with valid role change" do
      let(:new_role) { User::HMRC_ADMIN }

      it { is_expected.to redirect_to users_path }

      it "updates the user's role", :aggregate_failures do
        make_request
        target_user.reload
        expect(target_user.current_role).to eq(User::HMRC_ADMIN)
        expect(target_user.roles.count).to eq(1)
      end

      it "removes the previous role", :aggregate_failures do
        expect(target_user.current_role).to eq(User::GUEST)
        make_request
        target_user.reload
        expect(target_user.current_role).to eq(User::HMRC_ADMIN)
        expect(target_user.guest?).to be(false)
      end
    end

    context "with invalid role" do
      let(:new_role) { "INVALID_ROLE" }

      it { is_expected.to have_http_status :unprocessable_content }
    end

    context "when changing role multiple times" do
      it "ensures only one role exists", :aggregate_failures do
        target_user.set_role(User::TECHNICAL_OPERATOR)
        target_user.save!

        patch user_path(target_user), params: { user: { role: User::AUDITOR } }
        target_user.reload

        expect(target_user.current_role).to eq(User::AUDITOR)
        expect(target_user.roles.count).to eq(1)
      end
    end
  end

  context "when unauthenticated" do
    let(:authenticate_user) { false }
    let(:extra_session) { {} }

    it "redirects to the configured authentication provider" do
      expect_unauthenticated_redirect(-> { get users_path })
    end
  end

  context "when unauthorised" do
    let(:current_user) { create(:user, :guest) }
    let(:make_request) { get users_path }

    it { is_expected.to have_http_status :forbidden }
  end

  context "when non-technical operator tries to edit" do
    let(:current_user) { create(:user, :hmrc_admin_role) }
    let(:make_request) { get edit_user_path(target_user) }

    it { is_expected.to have_http_status :forbidden }
  end

  context "when using basic auth" do
    before do
      allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(true)
      allow(TradeTariffAdmin).to receive(:authorization_enabled?).and_return(false)
    end

    let(:current_user) { create(:user, :guest) }

    describe "GET #index" do
      let(:make_request) { get users_path }

      it { is_expected.to have_http_status :success }
    end

    describe "GET #edit" do
      let(:make_request) { get edit_user_path(target_user) }

      it { is_expected.to have_http_status :success }
    end

    describe "PATCH #update" do
      let(:make_request) do
        patch user_path(target_user),
              params: { user: { role: User::HMRC_ADMIN } }
      end

      it { is_expected.to redirect_to users_path }

      it "allows role update regardless of user role" do
        make_request
        target_user.reload
        expect(target_user.current_role).to eq(User::HMRC_ADMIN)
      end
    end
  end
end

