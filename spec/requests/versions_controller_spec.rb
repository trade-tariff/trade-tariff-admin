RSpec.describe VersionsController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }
  let(:versions_data) do
    [
      {
        "id" => "1",
        "type" => "version",
        "attributes" => {
          "item_type" => "GoodsNomenclatureLabel",
          "item_id" => "12345",
          "event" => "update",
          "whodunnit" => current_user.uid,
          "created_at" => "2025-06-15T10:00:00Z",
          "object" => { "goods_nomenclature_item_id" => "0101210000" },
        },
      },
      {
        "id" => "2",
        "type" => "version",
        "attributes" => {
          "item_type" => "GoodsNomenclatureSelfText",
          "item_id" => "67890",
          "event" => "create",
          "whodunnit" => nil,
          "created_at" => "2025-06-14T09:00:00Z",
          "object" => {},
        },
      },
    ]
  end
  let(:versions_response) do
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: versions_data,
        meta: { pagination: { page: 1, per_page: 20, total_count: 2 } },
      }.to_json,
    }
  end

  before do
    TradeTariffAdmin::ServiceChooser.service_choice = "uk"
  end

  describe "GET #index" do
    let(:make_request) { get versions_path }

    before do
      stub_api_request("/versions", backend: "uk")
        .with(query: hash_including({}))
        .and_return(versions_response)
    end

    it { is_expected.to have_http_status :success }
    it { is_expected.to render_template(:index) }

    it "displays version entries" do # rubocop:disable RSpec/MultipleExpectations
      expect(rendered_page.body).to include("Label")
      expect(rendered_page.body).to include("0101210000")
    end

    context "when filtering by item_type" do
      let(:make_request) { get versions_path(item_type: "GoodsNomenclatureLabel") }

      it { is_expected.to have_http_status :success }
    end

    context "when API fails" do
      before do
        stub_api_request("/versions", backend: "uk")
          .with(query: hash_including({}))
          .and_return(status: 500, body: { error: "Internal Server Error" }.to_json)
      end

      it { is_expected.to have_http_status :success }

      it "displays empty state" do
        expect(rendered_page.body).to include("No changes found")
      end
    end
  end

  describe "POST #restore" do
    let(:version_id) { 42 }

    context "when successful" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:make_request) { post restore_version_path(version_id) }
      let(:restore_response) do
        {
          status: 200,
          headers: { "content-type" => "application/json; charset=utf-8" },
          body: {
            data: {
              id: "99",
              type: "version",
              attributes: {
                item_type: "GoodsNomenclatureLabel",
                item_id: "12345",
                event: "update",
                object: { "goods_nomenclature_item_id" => "0101210000" },
              },
            },
          }.to_json,
        }
      end

      before do
        stub_api_request("/versions/#{version_id}/restore", :post, backend: "uk")
          .and_return(restore_response)
      end

      it { is_expected.to redirect_to(goods_nomenclature_label_path("0101210000")) }

      it "shows a success message" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Restored successfully.")
      end
    end

    context "when version not found" do
      let(:make_request) { post restore_version_path(version_id) }

      before do
        stub_api_request("/versions/#{version_id}/restore", :post, backend: "uk")
          .and_return(status: 404, body: { error: "Not found" }.to_json)
      end

      it { is_expected.to redirect_to(versions_path) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Version not found.")
      end
    end

    context "when API fails" do
      let(:make_request) { post restore_version_path(version_id) }

      before do
        stub_api_request("/versions/#{version_id}/restore", :post, backend: "uk")
          .and_return(status: 500, body: { error: "Server error" }.to_json)
      end

      it { is_expected.to redirect_to(versions_path) }

      it "shows an error message" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to include("Failed to restore")
      end
    end
  end

  context "when user is HMRC admin (unauthorized)" do
    let(:current_user) { create(:user, :hmrc_admin) }
    let(:make_request) { get versions_path }

    it { is_expected.to have_http_status :forbidden }
  end

  context "when user is auditor (unauthorized)" do
    let(:current_user) { create(:user, :auditor) }
    let(:make_request) { get versions_path }

    it { is_expected.to have_http_status :forbidden }
  end

  context "when user is guest (unauthorized)" do
    let(:current_user) { create(:user, :guest) }
    let(:make_request) { get versions_path }

    it { is_expected.to have_http_status :forbidden }
  end
end
