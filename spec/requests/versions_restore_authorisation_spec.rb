# A restore writes the record that the version belongs to, so it must obey the
# same rule as a direct edit of that record. The restore call is stubbed in
# every example below. A request that is not refused therefore redirects, and
# only authorisation can produce a 403.
RSpec.describe "Version restore authorisation", type: :request do
  subject(:rendered_page) { post restore_version_path(77) and response }

  include_context "with authenticated user"

  let(:item_type) { "AdminConfiguration" }

  before do
    TradeTariffAdmin::ServiceChooser.service_choice = "uk"

    stub_api_request("/versions/77", backend: "uk").and_return(version_response)
    stub_api_request("/versions/77/restore", :post, backend: "uk").and_return(version_response)
  end

  def version_response
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: {
          id: "77",
          type: "version",
          attributes: {
            item_type:,
            item_id: "some_setting",
            event: "update",
            object: { "name" => "some_setting" },
          },
        },
      }.to_json,
    }
  end

  context "when a superadmin restores a configuration version" do
    let(:current_user) { create(:user, :superadmin) }

    it { is_expected.to have_http_status :redirect }
  end

  context "when a technical operator restores a configuration version" do
    let(:current_user) { create(:user, :technical_operator) }

    it { is_expected.to have_http_status :forbidden }
  end

  context "when an auditor restores a configuration version" do
    let(:current_user) { create(:user, :auditor) }

    it { is_expected.to have_http_status :forbidden }
  end

  context "when a technical operator restores a label version" do
    let(:current_user) { create(:user, :technical_operator) }
    let(:item_type) { "GoodsNomenclatureLabel" }

    it { is_expected.to have_http_status :redirect }
  end

  context "when an hmrc admin restores a label version" do
    let(:current_user) { create(:user, :hmrc_admin) }
    let(:item_type) { "GoodsNomenclatureLabel" }

    it { is_expected.to have_http_status :forbidden }
  end

  context "when the item type is not recognised" do
    let(:current_user) { create(:user, :superadmin) }
    let(:item_type) { "SomeUnknownType" }

    it { is_expected.to have_http_status :forbidden }
  end
end
