RSpec.describe RollbacksController do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"
  let(:current_user) { create(:user, :superadmin) }

  describe "GET #index" do
    before do
      stub_api_request("/rollbacks?page=1").and_return \
        jsonapi_response :rollbacks, attributes_for_list(:rollback, 3)
    end

    let(:make_request) { get rollbacks_path }

    it { is_expected.to have_http_status :success }
  end

  context "when unauthenticated" do
    let(:authenticate_user) { false }
    let(:extra_session) { {} }

    it "redirects to the configured authentication provider" do
      expect_unauthenticated_redirect(-> { get rollbacks_path })
    end
  end

  context "when unauthorised" do
    let(:current_user) { create(:user, :guest) }

    let(:make_request) { get rollbacks_path }

    it { is_expected.to have_http_status :forbidden }
    it { is_expected.to have_attributes body: /contact your Delivery Manager/ }
  end

  context "when technical operator" do
    let(:current_user) { create(:user, :technical_operator) }
    let(:make_request) { get rollbacks_path }

    it { is_expected.to have_http_status :success }
  end

  context "when auditor" do
    let(:current_user) { create(:user, :auditor) }
    let(:make_request) { get rollbacks_path }

    it { is_expected.to have_http_status :success }
  end

  describe "POST #create" do
    let(:make_request) do
      post rollbacks_path, params: { rollback: { date: Time.zone.today.to_s, keep: true, reason: "Test rollback" } }
    end

    context "when technical operator" do
      let(:current_user) { create(:user, :technical_operator) }

      it { is_expected.to have_http_status :forbidden }
    end
  end
end
