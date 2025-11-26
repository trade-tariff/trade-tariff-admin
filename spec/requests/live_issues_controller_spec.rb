RSpec.describe LiveIssuesController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, permissions: ["signin", "HMRC Editor"]) }
  let(:live_issue) { build :live_issue }

  before do
    TradeTariffAdmin::ServiceChooser.service_choice = "uk"
  end

  describe "GET #index" do
    before do
      stub_api_request("/live_issues?page=1").and_return \
        jsonapi_response(:live_issue, attributes_for_list(:live_issue, 3))
    end

    let(:make_request) { get live_issues_path }

    it "returns http success", :aggregate_failures do
      expect(rendered_page).to have_http_status :success
      expect(rendered_page.body).to include("Manage live issues")
      expect(rendered_page.body).to include(live_issue.title)
    end
  end

  describe "GET #new" do
    let(:make_request) { get new_live_issue_path }

    it { is_expected.to have_http_status :ok }
  end

  describe "POST #create" do
    before do
      stub_api_request("/live_issues", :post).to_return create_response
    end

    let :make_request do
      post live_issues_path,
           params: { live_issue: live_issues_params }
    end

    context "with valid params" do
      let(:live_issues_params) { live_issue.attributes }
      let(:create_response) { webmock_response(:created, live_issue.attributes) }

      it { is_expected.to redirect_to live_issues_path }
    end

    context "with invalid params" do
      let(:live_issues_params) { live_issue.attributes.without(:title) }
      let(:create_response) { webmock_response(:error, title: "can't be blank'") }

      it { is_expected.to have_http_status :ok }
      it { is_expected.to have_attributes body: /can.+t be blank/ }
    end
  end

  describe "GET #edit" do
    before do
      stub_api_request("/live_issues/#{live_issue.id}")
        .and_return jsonapi_response(:live_issue, live_issue.attributes)
    end

    let(:make_request) { get edit_live_issue_path(live_issue.id) }

    it { is_expected.to have_http_status :success }
  end

  describe "PATCH #update" do
    before do
      stub_api_request("/live_issues/#{live_issue.id}")
        .and_return jsonapi_response(:live_issue, live_issue.attributes)

      stub_api_request("/live_issues/#{live_issue.id}", :patch)
        .and_return patch_response
    end

    let :make_request do
      patch live_issue_path(live_issue),
            params: { live_issue: live_issue.attributes.merge(status: new_status) }
    end

    context "with valid change" do
      let(:new_status) { "Resolved" }
      let(:patch_response) { webmock_response :updated, "/admin/live_issues/#{live_issue.id}" }

      it "success", :aggregate_failures do
        expect(rendered_page).to have_http_status :redirect
        expect(rendered_page).to redirect_to(live_issues_path)
      end

      it "sets the session" do
        rendered_page

        expect(
          session.dig("flash", "flashes", "notice"),
        ).to eql("Live issue updated")
      end
    end

    context "with invalid change" do
      let(:new_status) { "Invalid" }
      let(:patch_response) { webmock_response :error, status: "is not in range or set: [\'Active\', \'Resolved\']" }

      it { is_expected.to redirect_to live_issues_path }

      it "sets the session" do
        rendered_page

        expect(
          session.dig("flash", "flashes", "alert"),
        ).to include("Live issue could not be updated")
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      stub_api_request("/live_issues/#{live_issue.id}")
        .and_return jsonapi_response(:live_issue, live_issue.attributes)

      stub_api_request("/live_issues/#{live_issue.id}", :delete)
        .and_return webmock_response :no_content
    end

    let(:make_request) { delete live_issue_path(live_issue) }

    it { is_expected.to redirect_to live_issues_path }

    it "sets the session" do
      rendered_page

      expect(
        session.dig("flash", "flashes", "notice"),
      ).to eql("Live issue deleted")
    end
  end

  context "when unauthenticated" do
    let(:authenticate_user) { false }
    let(:extra_session) { {} }

    it "redirects to the configured authentication provider" do
      expect_unauthenticated_redirect(-> { get live_issues_path })
    end
  end

  context "when unauthorised" do
    let(:current_user) { create(:user, permissions: %w[]) }
    let(:make_request) { get live_issues_path }

    it { is_expected.to have_http_status :forbidden }
    it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
  end
end
