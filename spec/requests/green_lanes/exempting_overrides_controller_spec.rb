RSpec.describe GreenLanes::ExemptingOverridesController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:exempting_certificate_override) { build :exempting_certificate_override }
  let(:exempting_additional_code_override) { build :exempting_additional_code_override }
  let(:create_user) { create :user, permissions: ["signin", "HMRC Editor"] }

  before do
    allow(TradeTariffAdmin::ServiceChooser).to receive(:service_choice).and_return "xi"
  end

  describe "GET #index" do
    before do
      stub_api_request("/admin/green_lanes/exempting_certificate_overrides?page=1", backend: "xi").and_return \
        jsonapi_response :exempting_certificate_overrides, attributes_for_list(:exempting_certificate_override, 3)
      stub_api_request("/admin/green_lanes/exempting_additional_code_overrides?page=1", backend: "xi").and_return \
        jsonapi_response :exempting_additional_code_overrides, attributes_for_list(:exempting_additional_code_override, 3)
    end

    let(:make_request) { get green_lanes_exempting_overrides_path }

    it { is_expected.to have_http_status :success }
    it { is_expected.not_to include "div.current-service" }
  end
end
