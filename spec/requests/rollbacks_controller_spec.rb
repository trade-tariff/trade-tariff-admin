RSpec.describe RollbacksController do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"
  let(:current_user) { create(:user, :superadmin) }

  def stub_rollbacks_index
    stub_api_request("/rollbacks?page=1").and_return \
      jsonapi_response :rollbacks, attributes_for_list(:rollback, 3)
  end

  describe "GET #index" do
    before { stub_rollbacks_index }

    let(:make_request) { get rollbacks_path }

    it { is_expected.to have_http_status :success }
  end

  describe "GET #new" do
    let(:make_request) { get new_rollback_path }

    it { is_expected.to have_http_status :success }

    context "when technical operator" do
      let(:current_user) { create(:user, :technical_operator) }

      it { is_expected.to have_http_status :forbidden }
    end

    context "when auditor" do
      let(:current_user) { create(:user, :auditor) }

      it { is_expected.to have_http_status :forbidden }
    end
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

    before { stub_rollbacks_index }

    it { is_expected.to have_http_status :success }
    it { is_expected.not_to have_attributes body: /New Rollback/ }
  end

  context "when auditor" do
    let(:current_user) { create(:user, :auditor) }
    let(:make_request) { get rollbacks_path }

    before { stub_rollbacks_index }

    it { is_expected.to have_http_status :success }
    it { is_expected.not_to have_attributes body: /New Rollback/ }
  end

  describe "POST #create" do
    before do
      stub_api_request("/rollbacks", :post).to_return(api_created_response)
    end

    let(:make_request) do
      post rollbacks_path, params: { rollback: { date: Time.zone.today.to_s, keep: true, reason: "Test rollback" } }
    end

    it { is_expected.to redirect_to(rollbacks_path) }

    context "when technical operator" do
      let(:current_user) { create(:user, :technical_operator) }

      it { is_expected.to have_http_status :forbidden }
    end

    context "when auditor" do
      let(:current_user) { create(:user, :auditor) }

      it { is_expected.to have_http_status :forbidden }
    end
  end
end
