RSpec.describe ReportsController do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  describe "GET #index" do
    before do
      stub_api_request("/reports").and_return jsonapi_response(:report, [
        { resource_id: "commodities", name: "Commodities report", description: "Commodity export", available: true, dependencies_missing: false, missing_dependencies: [], download_url: "https://reporting.trade-tariff.service.gov.uk/uk/reporting/file.csv" },
        { resource_id: "differences", name: "Differences report", description: "Potential issues", available: false, dependencies_missing: true, missing_dependencies: ["UK commodities report", "XI commodities report"], download_url: nil },
      ])
    end

    let(:make_request) { get reports_path }

    it { is_expected.to have_http_status :success }

    it "renders report names" do
      rendered_page
      expect(response.body).to include("Commodities report", "Differences report")
    end

    it "renders the dependency warning when dependencies are missing" do
      rendered_page
      expect(response.body).to include("Missing dependencies: UK commodities report and XI commodities report.")
    end
  end

  describe "GET #show" do
    before do
      stub_api_request("/reports/commodities").and_return jsonapi_response(
        :report,
        { resource_id: "commodities", name: "Commodities report", description: "Commodity export", available: true, dependencies_missing: false, missing_dependencies: [], download_url: "https://reporting.trade-tariff.service.gov.uk/uk/reporting/file.csv" },
      )
    end

    let(:make_request) { get report_path("commodities") }

    it { is_expected.to have_http_status :success }

    it "renders the report details" do
      rendered_page
      expect(response.body).to include("Commodities report", "Commodity export")
    end
  end

  describe "GET #download" do
    before do
      stub_api_request("/reports/commodities").and_return jsonapi_response(
        :report,
        { resource_id: "commodities", name: "Commodities report", description: "Commodity export", available: true, dependencies_missing: false, missing_dependencies: [], download_url: "https://reporting.trade-tariff.service.gov.uk/uk/reporting/file.csv" },
      )
    end

    let(:make_request) { get download_report_path("commodities") }

    it { is_expected.to redirect_to("https://reporting.trade-tariff.service.gov.uk/uk/reporting/file.csv") }
  end

  describe "POST #run" do
    before do
      stub_api_request("/reports/commodities").and_return jsonapi_response(
        :report,
        { resource_id: "commodities", name: "Commodities report", description: "Commodity export", available: true, dependencies_missing: false, missing_dependencies: [], download_url: "https://reporting.trade-tariff.service.gov.uk/uk/reporting/file.csv" },
      )
      stub_api_request("/reports/commodities/run", :post).to_return(status: 202, body: "", headers: {})
    end

    let(:make_request) { post run_report_path("commodities") }

    it { is_expected.to redirect_to(report_path("commodities")) }

    it "shows a success message" do
      rendered_page
      expect(flash[:notice]).to eq("Report generation was scheduled.")
    end
  end

  context "when unauthorised" do
    let(:current_user) { create(:user, :guest) }
    let(:make_request) { get reports_path }

    it { is_expected.to have_http_status :forbidden }
  end
end
