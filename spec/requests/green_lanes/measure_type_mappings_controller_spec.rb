RSpec.describe GreenLanes::MeasureTypeMappingsController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:measure_type_mapping) { build :measure_type_mapping }
  let(:create_user) { create :user, :technical_operator }

  before do
    allow(TradeTariffAdmin::ServiceChooser).to receive(:service_choice).and_return "xi"

    stub_api_request("/admin/green_lanes/themes", backend: "xi").and_return \
      jsonapi_response :themes, attributes_for_list(:green_lanes_theme, 3)
  end

  describe "GET #index" do
    before do
      stub_api_request("/admin/green_lanes/measure_type_mappings?page=1", backend: "xi").and_return \
        jsonapi_response :measure_type_mappings, attributes_for_list(:measure_type_mapping, 3)
    end

    let(:make_request) { get green_lanes_measure_type_mappings_path }

    it { is_expected.to have_http_status :success }
    it { is_expected.not_to include "div.current-service" }
  end

  describe "GET #new" do
    let(:make_request) { get new_green_lanes_measure_type_mapping_path }

    it { is_expected.to have_http_status :ok }
    it { is_expected.not_to include "div.current-service" }
  end

  describe "POST #create" do
    before do
      stub_api_request("/admin/green_lanes/measure_type_mappings", :post).to_return create_response
    end

    let :make_request do
      post green_lanes_measure_type_mappings_path,
           params: { measure_type_mapping: mtm_params }
    end

    context "with valid item" do
      let(:mtm_params) { measure_type_mapping.attributes.without(:id) }
      let(:create_response) { webmock_response(:created, measure_type_mapping.attributes) }

      it { is_expected.to redirect_to green_lanes_measure_type_mappings_path }
    end

    context "with invalid item" do
      let(:mtm_params) { measure_type_mapping.attributes.without(:id, :theme_id) }
      let(:create_response) { webmock_response(:error, theme_id: "can't be blank'") }

      it { is_expected.to have_http_status :ok }
      it { is_expected.to have_attributes body: /can.+t be blank/ }
      it { is_expected.not_to include "div.current-service" }
    end
  end

  describe "DELETE #destroy" do
    before do
      stub_api_request("/admin/green_lanes/measure_type_mappings/#{measure_type_mapping.id}")
        .and_return jsonapi_response(:measure_type_mapping, measure_type_mapping.attributes)

      stub_api_request("/admin/green_lanes/measure_type_mappings/#{measure_type_mapping.id}", :delete)
        .and_return webmock_response :no_content
    end

    let(:make_request) { delete green_lanes_measure_type_mapping_path(measure_type_mapping) }

    it { is_expected.to redirect_to green_lanes_measure_type_mappings_path }
  end
end
