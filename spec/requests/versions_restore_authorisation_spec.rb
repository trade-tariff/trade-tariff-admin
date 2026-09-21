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
            item_id: "12345",
            event: "update",
            object: {
              "name" => "some_setting",
              "goods_nomenclature_item_id" => "0101210000",
              "customs_tariff_update_version" => "1",
            },
          },
        },
      }.to_json,
    }
  end

  # Configuration: SUPERADMIN only, because a direct edit is SUPERADMIN only.
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

  context "when an hmrc admin restores a configuration version" do
    let(:current_user) { create(:user, :hmrc_admin) }

    it { is_expected.to have_http_status :forbidden }
  end

  # Labels, self-texts and intercepts: TECHNICAL_OPERATOR only.
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

  context "when a technical operator restores a self text version" do
    let(:current_user) { create(:user, :technical_operator) }
    let(:item_type) { "GoodsNomenclatureSelfText" }

    it { is_expected.to have_http_status :redirect }
  end

  context "when an auditor restores a self text version" do
    let(:current_user) { create(:user, :auditor) }
    let(:item_type) { "GoodsNomenclatureSelfText" }

    it { is_expected.to have_http_status :forbidden }
  end

  context "when a technical operator restores a description intercept version" do
    let(:current_user) { create(:user, :technical_operator) }
    let(:item_type) { "DescriptionIntercept" }

    it { is_expected.to have_http_status :redirect }
  end

  context "when an hmrc admin restores a description intercept version" do
    let(:current_user) { create(:user, :hmrc_admin) }
    let(:item_type) { "DescriptionIntercept" }

    it { is_expected.to have_http_status :forbidden }
  end

  # Compressed notes: TECHNICAL_OPERATOR only. The compressed note page offers
  # a restore control, so the portal must authorise the type. The backend does
  # not accept the type, so the restore then fails there. See gap 12.
  context "when a technical operator restores a compressed note version" do
    let(:current_user) { create(:user, :technical_operator) }
    let(:item_type) { "TariffKnowledge::CompressedNote" }

    it { is_expected.to have_http_status :redirect }
  end

  context "when an hmrc admin restores a compressed note version" do
    let(:current_user) { create(:user, :hmrc_admin) }
    let(:item_type) { "TariffKnowledge::CompressedNote" }

    it { is_expected.to have_http_status :forbidden }
  end

  # Section and chapter notes: TECHNICAL_OPERATOR only.
  context "when a technical operator restores a section note version" do
    let(:current_user) { create(:user, :technical_operator) }
    let(:item_type) { "CustomsTariffSectionNote" }

    it { is_expected.to have_http_status :redirect }
  end

  context "when an auditor restores a section note version" do
    let(:current_user) { create(:user, :auditor) }
    let(:item_type) { "CustomsTariffSectionNote" }

    it { is_expected.to have_http_status :forbidden }
  end

  context "when a technical operator restores a chapter note version" do
    let(:current_user) { create(:user, :technical_operator) }
    let(:item_type) { "CustomsTariffChapterNote" }

    it { is_expected.to have_http_status :redirect }
  end

  context "when an auditor restores a chapter note version" do
    let(:current_user) { create(:user, :auditor) }
    let(:item_type) { "CustomsTariffChapterNote" }

    it { is_expected.to have_http_status :forbidden }
  end

  # The Admin Portal has no screen for a goods nomenclature intercept, so no
  # role may restore one. The backend accepts the type, so the denial must be
  # explicit here rather than assumed from the missing screen.
  context "when a superadmin restores a goods nomenclature intercept version" do
    let(:current_user) { create(:user, :superadmin) }
    let(:item_type) { "GoodsNomenclatureIntercept" }

    it { is_expected.to have_http_status :forbidden }
  end

  context "when the item type is not recognised" do
    let(:current_user) { create(:user, :superadmin) }
    let(:item_type) { "SomeUnknownType" }

    it { is_expected.to have_http_status :forbidden }
  end
end
