RSpec.describe UsersController do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }
  let(:target_user) { create(:user, :guest) }
  let(:new_user_params) do
    {
      email: "new.user@example.com",
      role: User::AUDITOR,
    }
  end

  describe "GET #index" do
    let(:make_request) { get users_path }

    it { is_expected.to have_http_status :success }
  end

  describe "GET #new" do
    let(:current_user) { create(:user, :superadmin) }
    let(:make_request) { get new_user_path }

    it { is_expected.to have_http_status :success }

    it "displays fields for email and role selection", :aggregate_failures do
      rendered_page

      expect(response.body).to include("Email address", "radio", User::SUPERADMIN, User::GUEST, User::TECHNICAL_OPERATOR, User::HMRC_ADMIN, User::AUDITOR)
    end
  end

  describe "GET #edit" do
    let(:make_request) { get edit_user_path(target_user) }

    it { is_expected.to have_http_status :success }

    it "displays radio buttons for role selection", :aggregate_failures do
      rendered_page
      expect(response.body).to include("radio", User::SUPERADMIN, User::GUEST, User::TECHNICAL_OPERATOR, User::HMRC_ADMIN, User::AUDITOR)
    end

    it "preselects the current role" do
      rendered_page
      expect(response.body).to include("checked")
    end
  end

  describe "POST #create" do
    let(:current_user) { create(:user, :superadmin) }
    let(:make_request) do
      post users_path,
           params: { user: new_user_params }
    end

    it { is_expected.to redirect_to users_path }

    it "creates the user with the selected role", :aggregate_failures do
      expect { make_request }.to change(User, :count).by(1)

      created_user = User.order(:created_at).last

      expect(created_user.email).to eq("new.user@example.com")
      expect(created_user.current_role).to eq(User::AUDITOR)
    end

    it "normalizes the email address" do
      post users_path, params: { user: new_user_params.merge(email: "  NEW.USER@EXAMPLE.COM ") }

      expect(User.order(:created_at).last.email).to eq("new.user@example.com")
    end

    context "with a blank email address" do
      let(:new_user_params) do
        super().merge(email: "")
      end

      it { is_expected.to have_http_status :unprocessable_content }

      it "renders the email validation error" do
        make_request

        expect(response.body).to include("There is a problem", "can&#39;t be blank")
      end
    end

    context "with an invalid email address" do
      let(:new_user_params) do
        super().merge(email: "not-an-email")
      end

      it { is_expected.to have_http_status :unprocessable_content }

      it "renders the invalid email error" do
        make_request

        expect(response.body).to include("There is a problem", "is invalid")
      end

      it "does not create the user" do
        expect { make_request }.not_to change(User, :count)
      end
    end

    context "when the email address already exists" do
      before do
        create(:user, email: "new.user@example.com")
      end

      it { is_expected.to have_http_status :unprocessable_content }

      it "does not create a duplicate user" do
        expect { make_request }.not_to change(User, :count)
      end

      it "renders the duplicate email validation error" do
        make_request

        expect(response.body).to include("There is a problem", "has already been taken")
      end
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
        expect(target_user.role).to eq(User::HMRC_ADMIN)
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
      it "updates the role correctly", :aggregate_failures do
        target_user.role = User::TECHNICAL_OPERATOR
        target_user.save!
        patch user_path(target_user), params: { user: { role: User::AUDITOR } }
        expect(target_user.reload).to have_attributes(current_role: User::AUDITOR, role: User::AUDITOR)
      end
    end
  end

  describe "DELETE #destroy" do
    let(:current_user) { create(:user, :superadmin) }
    let(:make_request) { delete user_path(target_user) }

    it { is_expected.to redirect_to users_path }

    it "removes the user" do
      target_user

      expect { make_request }.to change(User, :count).by(-1)
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
    let(:current_user) { create(:user, :hmrc_admin) }
    let(:make_request) { get edit_user_path(target_user) }

    it { is_expected.to have_http_status :forbidden }
  end

  context "when non-technical operator tries to add a user" do
    let(:current_user) { create(:user, :hmrc_admin) }
    let(:make_request) { get new_user_path }

    it { is_expected.to have_http_status :forbidden }
  end

  context "when technical operator tries to add a user" do
    let(:make_request) { get new_user_path }

    it { is_expected.to have_http_status :forbidden }
  end

  context "when non-superadmin tries to remove a user" do
    let(:current_user) { create(:user, :hmrc_admin) }
    let(:make_request) { delete user_path(target_user) }

    it { is_expected.to have_http_status :forbidden }
  end

  context "when technical operator tries to remove a user" do
    let(:make_request) { delete user_path(target_user) }

    it { is_expected.to have_http_status :forbidden }
  end

  context "when using basic auth" do
    before do
      allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(true)
      allow(Rails.env).to receive(:production?).and_return(false)
    end

    let(:current_user) { create(:user, :hmrc_admin) }

    describe "GET #index" do
      let(:make_request) { get users_path }

      it { is_expected.to have_http_status :success }
    end

    describe "GET #edit" do
      let(:make_request) { get edit_user_path(target_user) }

      it { is_expected.to have_http_status :success }
    end

    describe "GET #new" do
      let(:make_request) { get new_user_path }

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

    describe "POST #create" do
      let(:make_request) do
        post users_path,
             params: { user: new_user_params }
      end

      it { is_expected.to redirect_to users_path }
    end

    describe "DELETE #destroy" do
      let(:make_request) { delete user_path(target_user) }

      it { is_expected.to redirect_to users_path }
    end
  end
end
