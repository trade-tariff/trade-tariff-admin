RSpec.describe DistributionListsController, type: :request do
  include_context "with authenticated user"
  include_context "with distribution lists"

  describe "GET #index" do
    subject(:make_request) { get distribution_lists_path }

    it "lists only dl- groups", :aggregate_failures do
      make_request

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("dl-tariff-notifications", "Tariff notifications")
      expect(response.body).not_to match(/>(admin|myott|portal)</)
    end

    it "is not cached" do
      make_request

      expect(response.headers["Cache-Control"]).to eq("no-store")
    end

    it "shows the Distribution lists navigation link" do
      make_request

      expect(response.body).to include(">Distribution lists<")
    end

    context "when Cognito is unavailable" do
      before { cognito_client.stub_responses(:list_groups, "TooManyRequestsException") }

      it "renders an error" do
        make_request

        expect(response).to have_http_status(:service_unavailable)
      end
    end

    %i[hmrc_admin auditor guest].each do |role|
      context "when the user is #{role}" do
        let(:current_user) { create(:user, role) }

        it "is forbidden and does not call Cognito", :aggregate_failures do
          make_request

          expect(response).to have_http_status(:forbidden)
          expect(cognito_client.api_requests).to be_empty
        end
      end
    end

    context "when no Cognito user pool is configured" do
      before { allow(TradeTariffAdmin).to receive(:cognito_user_pool_id).and_return(nil) }

      it "does not route the request" do
        make_request

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET #show" do
    it "shows the members and the subscribe form", :aggregate_failures do
      get distribution_list_path("dl-tariff-notifications")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(recipient_email, "Subscribe", "Recipients (1)")
      expect(response.body).to include(remove_distribution_list_recipient_path("dl-tariff-notifications", recipient_sub))
      expect(response.headers["Cache-Control"]).to eq("no-store")
    end

    it "shows recent changes without email addresses", :aggregate_failures do
      DistributionListAuditEvent.create!(actor_uid: "operator-9", actor_name: "Olivia Operator", action: "user_deleted", group_name: "dl-tariff-notifications", recipient_username: "gone-sub")
      get distribution_list_path("dl-tariff-notifications")

      expect(response.body).to include("Recent changes", "Olivia Operator", "Cognito user and email deleted", "gone-sub")
    end

    it "redirects for an unknown dl- group" do
      get distribution_list_path("dl-unknown")

      expect(response).to redirect_to(distribution_lists_path)
    end

    it "does not route a role group", :aggregate_failures do
      get "/distribution_lists/admin"

      expect(response).to have_http_status(:not_found)
      expect(cognito_requests(:list_users_in_group)).to be_empty
    end
  end
end
