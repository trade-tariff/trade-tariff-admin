RSpec.describe UsersController do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }
  let(:target_user) { create(:user, :guest) }
  let(:new_user_params) do
    {
      email: "new.user@example.com",
      name: "New User",
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

    it "displays fields for name, email and role selection", :aggregate_failures do
      rendered_page

      expect(response.body).to include("Name", "Email address", "radio", User::SUPERADMIN, User::GUEST, User::TECHNICAL_OPERATOR, User::HMRC_ADMIN, User::AUDITOR)
    end
  end

  describe "GET #edit" do
    let(:make_request) { get edit_user_path(target_user) }

    it { is_expected.to have_http_status :success }

    it "displays all roles and disables superadmin", :aggregate_failures do
      rendered_page
      document = Nokogiri::HTML(response.body)

      expect(response.body).to include("Name", "radio", User::SUPERADMIN, User::GUEST, User::TECHNICAL_OPERATOR, User::HMRC_ADMIN, User::AUDITOR)
      expect(document.at_css("input[type='radio'][value='SUPERADMIN']")["disabled"]).to eq("disabled")
      expect(document.at_css("input[type='radio'][value='HMRC_ADMIN']")["disabled"]).to be_nil
    end

    it "preselects the current role" do
      rendered_page
      expect(response.body).to include("checked")
    end

    context "when editing a superadmin" do
      let(:target_user) { create(:user, :superadmin) }

      it "disables every role option and preserves the current role", :aggregate_failures do
        rendered_page
        document = Nokogiri::HTML(response.body)

        expect(document.css("input[type='radio'][name='user[role]']")).to all(satisfy { |input| input["disabled"] == "disabled" })
        expect(document.at_css("input[type='hidden'][name='user[role]'][value='SUPERADMIN']")).not_to be_nil
      end
    end

    context "when current user is superadmin" do
      let(:current_user) { create(:user, :superadmin) }

      it "shows the superadmin role option" do
        rendered_page

        expect(response.body).to include(User::SUPERADMIN)
      end

      it "enables the superadmin role option" do
        rendered_page
        document = Nokogiri::HTML(response.body)

        expect(document.at_css("input[type='radio'][value='SUPERADMIN']")["disabled"]).to be_nil
      end
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
      expect(created_user.name).to eq("New User")
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

        expect(response.body).to include("There is a problem", "Email address can&#39;t be blank")
      end
    end

    context "with an invalid email address" do
      let(:new_user_params) do
        super().merge(email: "not-an-email")
      end

      it { is_expected.to have_http_status :unprocessable_content }

      it "renders the invalid email error" do
        make_request

        expect(response.body).to include("There is a problem", "Email address is invalid")
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

        expect(response.body).to include("There is a problem", "Email address has already been taken")
      end
    end

    context "with a blank name" do
      let(:new_user_params) do
        super().merge(name: "")
      end

      it { is_expected.to have_http_status :unprocessable_content }

      it "renders the name validation error" do
        make_request

        expect(response.body).to include("There is a problem", "Name can&#39;t be blank")
      end
    end

    context "when creating a superadmin" do
      let(:new_user_params) do
        super().merge(role: User::SUPERADMIN)
      end

      it "creates the user with the superadmin role" do
        make_request

        expect(User.order(:created_at).last.current_role).to eq(User::SUPERADMIN)
      end
    end
  end

  describe "PATCH #update" do
    def update_request(name:, role:)
      patch user_path(target_user),
            params: { user: { name:, role: } }
    end

    context "with valid role change" do
      it "redirects to users" do
        update_request(name: "Updated User", role: User::HMRC_ADMIN)

        expect(response).to redirect_to(users_path)
      end

      it "updates the user's details", :aggregate_failures do
        update_request(name: "Updated User", role: User::HMRC_ADMIN)

        target_user.reload
        expect(target_user.current_role).to eq(User::HMRC_ADMIN)
        expect(target_user.name).to eq("Updated User")
        expect(target_user.role).to eq(User::HMRC_ADMIN)
      end

      it "removes the previous role", :aggregate_failures do
        expect(target_user.current_role).to eq(User::GUEST)

        update_request(name: "Updated User", role: User::HMRC_ADMIN)

        target_user.reload
        expect(target_user.current_role).to eq(User::HMRC_ADMIN)
        expect(target_user.guest?).to be(false)
      end
    end

    context "with invalid role" do
      it "returns unprocessable content" do
        update_request(name: "Updated User", role: "INVALID_ROLE")

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when changing role multiple times" do
      it "updates the role correctly", :aggregate_failures do
        target_user.role = User::TECHNICAL_OPERATOR
        target_user.save!

        update_request(name: target_user.name, role: User::AUDITOR)

        expect(target_user.reload).to have_attributes(current_role: User::AUDITOR, role: User::AUDITOR)
      end
    end

    context "when technical operator tries to assign superadmin" do
      it "returns forbidden" do
        update_request(name: "Updated User", role: User::SUPERADMIN)

        expect(response).to have_http_status(:forbidden)
      end

      it "does not update the user role" do
        expect {
          update_request(name: "Updated User", role: User::SUPERADMIN)
        }.not_to(change { target_user.reload.current_role })
      end
    end

    context "when editing an existing superadmin" do
      let(:target_user) { create(:user, :superadmin) }

      it "allows updating the name while preserving the role", :aggregate_failures do
        update_request(name: "Updated User", role: User::SUPERADMIN)

        expect(response).to redirect_to(users_path)
        expect(target_user.reload).to have_attributes(name: "Updated User", current_role: User::SUPERADMIN, role: User::SUPERADMIN)
      end

      it "forbids changing the superadmin role" do
        update_request(name: "Updated User", role: User::HMRC_ADMIN)

        expect(response).to have_http_status(:forbidden)
      end

      it "does not change the superadmin role" do
        expect {
          update_request(name: "Updated User", role: User::HMRC_ADMIN)
        }.not_to(change { target_user.reload.current_role })
      end
    end

    context "with a blank name" do
      it "returns unprocessable content" do
        update_request(name: "", role: User::HMRC_ADMIN)

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "renders the name validation error" do
        update_request(name: "", role: User::HMRC_ADMIN)

        expect(response.body).to include("There is a problem", "Name can&#39;t be blank")
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
              params: { user: { name: target_user.name, role: User::HMRC_ADMIN } }
      end

      it { is_expected.to redirect_to users_path }

      it "allows role update within the user's ceiling" do
        make_request
        target_user.reload
        expect(target_user.current_role).to eq(User::HMRC_ADMIN)
      end
    end

    describe "POST #create with superadmin role" do
      let(:make_request) do
        post users_path,
             params: { user: new_user_params.merge(role: User::SUPERADMIN) }
      end

      it { is_expected.to have_http_status :forbidden }
    end

    describe "PATCH #update when assigning superadmin" do
      let(:make_request) do
        patch user_path(target_user),
              params: { user: { name: target_user.name, role: User::SUPERADMIN } }
      end

      it { is_expected.to have_http_status :forbidden }
    end

    describe "PATCH #update when assigning technical operator" do
      let(:make_request) do
        patch user_path(target_user),
              params: { user: { name: target_user.name, role: User::TECHNICAL_OPERATOR } }
      end

      it { is_expected.to have_http_status :forbidden }
    end

    describe "POST #create" do
      let(:make_request) do
        post users_path,
             params: { user: new_user_params }
      end

      it { is_expected.to redirect_to users_path }
    end

    describe "POST #create with technical operator role" do
      let(:make_request) do
        post users_path,
             params: { user: new_user_params.merge(role: User::TECHNICAL_OPERATOR) }
      end

      it { is_expected.to have_http_status :forbidden }
    end

    describe "DELETE #destroy" do
      let(:make_request) { delete user_path(target_user) }

      it { is_expected.to redirect_to users_path }
    end
  end
end
