RSpec.describe DistributionLists::RecipientsController, type: :request do
  include_context "with authenticated user"
  include_context "with distribution lists"
  include DistributionListLockHelper

  let(:group) { "dl-tariff-notifications" }
  let(:new_email) { "new.person@example.com" }
  let(:new_sub) { "99999999-8888-7777-6666-555555555555" }

  describe "POST #create" do
    subject(:make_request) do
      post distribution_list_recipients_path(group), params: { distribution_list_recipient_form: { email: " New.Person@Example.com " } }
    end

    context "when the user does not exist in Cognito" do
      before do
        cognito_client.stub_responses(:admin_get_user, "UserNotFoundException")
        cognito_client.stub_responses(:admin_create_user, user: { username: new_sub })
      end

      it "creates the user and subscribes it", :aggregate_failures do
        make_request

        expect(response).to redirect_to(distribution_list_path(group))
        expect(flash[:notice]).to eq("New user created and subscribed to the distribution list.")
        expect(cognito_requests(:admin_create_user).first[:params]).to include(username: new_email, message_action: "SUPPRESS")
        expect(cognito_requests(:admin_add_user_to_group).first[:params]).to include(username: new_sub, group_name: group)
      end
    end

    context "when the user already exists" do
      before { cognito_client.stub_responses(:admin_get_user, username: new_sub) }

      it "subscribes the user without creating one", :aggregate_failures do
        make_request

        expect(flash[:notice]).to eq("Recipient subscribed to the distribution list.")
        expect(cognito_requests(:admin_create_user)).to be_empty
      end
    end

    context "when checking privacy" do
      let(:log) { StringIO.new }

      before do
        cognito_client.stub_responses(:admin_get_user, username: new_sub)
        original_logger = Rails.logger
        Rails.logger = ActiveSupport::Logger.new(log)
        make_request
      ensure
        Rails.logger = original_logger
      end

      it "writes an audit log without the email", :aggregate_failures do
        expect(log.string).to include("distribution_list.recipient_added")
        expect(log.string.downcase).not_to include(new_email)
      end

      it "does not put the email in the flash" do
        expect(flash.to_h.values.join).not_to include(new_email)
      end
    end

    context "with an invalid email" do
      subject(:make_request) do
        post distribution_list_recipients_path(group), params: { distribution_list_recipient_form: { email: "not-an-email" } }
      end

      it "re-renders the form with an error", :aggregate_failures do
        make_request

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Enter an email address in the correct format")
        expect(cognito_requests(:admin_add_user_to_group)).to be_empty
      end
    end

    context "when Cognito fails" do
      before do
        cognito_client.stub_responses(:admin_get_user, username: new_sub)
        cognito_client.stub_responses(:admin_add_user_to_group, "TooManyRequestsException")
        cognito_client.stub_responses(:admin_list_groups_for_user, groups: [{ group_name: "myott" }])
      end

      it "redirects with a generic error" do
        make_request

        expect(flash[:alert]).to eq(DistributionListHandling::UNAVAILABLE_MESSAGE)
      end
    end

    context "when Cognito cannot be reached" do
      before do
        cognito_client.stub_responses(:admin_get_user, Seahorse::Client::NetworkingError.new(Net::OpenTimeout.new))
      end

      it "redirects with a generic error" do
        make_request

        expect(flash[:alert]).to eq(DistributionListHandling::UNAVAILABLE_MESSAGE)
      end
    end

    context "when a new user was created but the add and the cleanup both time out" do
      before do
        cognito_client.stub_responses(:admin_get_user, "UserNotFoundException")
        cognito_client.stub_responses(:admin_create_user, user: { username: new_sub })
        cognito_client.stub_responses(:admin_add_user_to_group, Seahorse::Client::NetworkingError.new(Net::ReadTimeout.new))
        cognito_client.stub_responses(:admin_list_groups_for_user, Seahorse::Client::NetworkingError.new(Net::ReadTimeout.new))
        make_request
      end

      it "tells the operator which Cognito user to check", :aggregate_failures do
        expect(response).to redirect_to(distribution_list_path(group))
        expect(flash[:alert]).to include("was not subscribed", new_sub)
      end
    end

    context "when a new user was created but could not be subscribed or removed" do
      before do
        cognito_client.stub_responses(:admin_get_user, "UserNotFoundException")
        cognito_client.stub_responses(:admin_create_user, user: { username: new_sub })
        cognito_client.stub_responses(:admin_add_user_to_group, "TooManyRequestsException")
        cognito_client.stub_responses(:admin_list_groups_for_user, groups: [])
        cognito_client.stub_responses(:admin_delete_user, "TooManyRequestsException")
        make_request
      end

      it "tells the operator which Cognito user to delete", :aggregate_failures do
        expect(response).to redirect_to(distribution_list_path(group))
        expect(flash[:alert]).to include("was not subscribed", new_sub)
        expect(flash[:alert]).not_to include(new_email)
      end
    end

    context "when the user is an HMRC admin" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it "is forbidden and does not call Cognito", :aggregate_failures do
        make_request

        expect(response).to have_http_status(:forbidden)
        expect(cognito_client.api_requests).to be_empty
      end
    end

    it "cannot target a role group", :aggregate_failures do
      post "/distribution_lists/admin/recipients", params: { distribution_list_recipient_form: { email: new_email } }

      expect(response).to have_http_status(:not_found)
      expect(cognito_requests(:admin_add_user_to_group)).to be_empty
    end
  end

  describe "GET #remove" do
    it "asks for confirmation", :aggregate_failures do
      get remove_distribution_list_recipient_path(group, recipient_sub)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Unsubscribe recipient?", recipient_email, "They are in other groups")
      expect(response.headers["Cache-Control"]).to eq("no-store")
    end

    it "warns when the account will be deleted", :aggregate_failures do
      cognito_client.stub_responses(:admin_list_groups_for_user, groups: [{ group_name: group }])
      get remove_distribution_list_recipient_path(group, recipient_sub)

      expect(response.body).to include("their Cognito account and email address will also be deleted")
      expect(response.body).to include('name="account_deletion_acknowledged" value="true"')
    end

    it "redirects when the recipient is not on the list" do
      get remove_distribution_list_recipient_path(group, "00000000-0000-0000-0000-000000000000")

      expect(response).to redirect_to(distribution_list_path(group))
    end
  end

  describe "DELETE #destroy" do
    subject(:make_request) do
      delete distribution_list_recipient_path(group, recipient_sub),
             params: { account_deletion_acknowledged: account_deletion_acknowledged.to_s }
    end

    let(:account_deletion_acknowledged) { false }

    it "removes the user from the group only when they are in other groups", :aggregate_failures do
      make_request

      expect(response).to redirect_to(distribution_list_path(group))
      expect(flash[:notice]).to eq("Recipient unsubscribed from the distribution list.")
      expect(cognito_requests(:admin_remove_user_from_group).first[:params]).to include(username: recipient_sub, group_name: group)
      expect(cognito_requests(:admin_delete_user)).to be_empty
    end

    it "audits who unsubscribed which recipient" do
      make_request

      expect(DistributionListAuditEvent.sole).to have_attributes(
        actor_uid: current_user.uid, action: "recipient_removed", group_name: group, recipient_username: recipient_sub,
      )
    end

    context "when the list was the last group the user was in" do
      let(:account_deletion_acknowledged) { true }

      before { cognito_client.stub_responses(:admin_list_groups_for_user, groups: []) }

      it "deletes the Cognito user", :aggregate_failures do
        make_request

        expect(flash[:notice]).to include("their Cognito account and email address were deleted")
        expect(cognito_requests(:admin_delete_user).first[:params]).to include(username: recipient_sub)
        expect(DistributionListAuditEvent.order(:id).pluck(:action)).to eq(%w[recipient_removed user_deleted])
      end
    end

    context "when the deletion fails" do
      let(:account_deletion_acknowledged) { true }

      before do
        cognito_client.stub_responses(:admin_list_groups_for_user, groups: [])
        cognito_client.stub_responses(:admin_delete_user, "TooManyRequestsException")
      end

      it "tells the operator which Cognito user to delete" do
        make_request

        expect(flash[:alert]).to include("could not be checked or deleted", recipient_sub)
      end
    end

    context "when the deletion times out and the user still exists" do
      let(:account_deletion_acknowledged) { true }

      before do
        cognito_client.stub_responses(:admin_list_groups_for_user, groups: [])
        cognito_client.stub_responses(:admin_delete_user, Seahorse::Client::NetworkingError.new(Net::ReadTimeout.new))
        cognito_client.stub_responses(:admin_get_user, username: recipient_sub)
      end

      it "tells the operator which Cognito user to delete" do
        make_request

        expect(flash[:alert]).to include("could not be checked or deleted", recipient_sub)
      end
    end

    context "when a confirmation that kept the account becomes stale" do
      before do
        get remove_distribution_list_recipient_path(group, recipient_sub)
        cognito_client.stub_responses(:admin_list_groups_for_user, groups: [{ group_name: group }])
        make_request
      end

      it "requires a new confirmation before removing the recipient", :aggregate_failures do
        expect(response).to redirect_to(remove_distribution_list_recipient_path(group, recipient_sub))
        expect(flash[:alert]).to include("Review the account deletion warning")
        expect(cognito_requests(:admin_remove_user_from_group)).to be_empty
        expect(cognito_requests(:admin_delete_user)).to be_empty
      end

      it "shows the irreversible deletion warning on the new confirmation page" do
        follow_redirect!

        expect(response.body).to include("their Cognito account and email address will also be deleted")
      end
    end

    it "handles a recipient that is already gone" do
      cognito_client.stub_responses(:admin_remove_user_from_group, "UserNotFoundException")
      make_request

      expect(flash[:alert]).to eq("Recipient is no longer in this distribution list.")
    end

    context "when the user is an auditor" do
      let(:current_user) { create(:user, :auditor) }

      it "is forbidden" do
        make_request

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context "when another request is changing the same recipient" do
    before { stub_const("DistributionListService::LOCK_TIMEOUT", 0.3) }

    let(:busy_message) { "Another change to this recipient is in progress. Try again." }

    context "when unsubscribing" do
      before do
        holding_distribution_list_lock(recipient_sub) { delete distribution_list_recipient_path(group, recipient_sub) }
      end

      it "asks the operator to try again and does not unsubscribe", :aggregate_failures do
        expect(response).to redirect_to(distribution_list_path(group))
        expect(flash[:alert]).to eq(busy_message)
        expect(cognito_requests(:admin_remove_user_from_group)).to be_empty
      end
    end

    context "when subscribing" do
      before do
        cognito_client.stub_responses(:admin_get_user, username: recipient_sub)
        holding_distribution_list_lock(recipient_sub) do
          post distribution_list_recipients_path(group), params: { distribution_list_recipient_form: { email: recipient_email } }
        end
      end

      it "asks the operator to try again and does not subscribe", :aggregate_failures do
        expect(response).to redirect_to(distribution_list_path(group))
        expect(flash[:alert]).to eq(busy_message)
        expect(cognito_requests(:admin_add_user_to_group)).to be_empty
      end
    end
  end
end
