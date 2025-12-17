RSpec.describe GreenLanes::MeasuresController do
  subject(:rendered_page) { create_user && make_request && response }

  let(:measure) { build :green_lanes_measure, :with_category_assessment }
  let(:create_user) { create :user, :technical_operator }

  before do
    allow(TradeTariffAdmin::ServiceChooser).to receive(:service_choice).and_return "xi"
  end

  describe "GET #index" do
    before do
      stub_api_request("/admin/green_lanes/measures?page=1", backend: "xi").and_return \
        jsonapi_response :measures, attributes_for_list(:green_lanes_measure, 3, :with_category_assessment, :with_goods_nomenclature)
    end

    let(:make_request) { get green_lanes_measures_path }

    it { is_expected.to have_http_status :success }
    it { is_expected.not_to include "div.current-service" }
  end

  describe "DELETE #destroy" do
    before do
      stub_api_request("/admin/green_lanes/measures/#{measure.id}")
        .and_return jsonapi_response(:green_lanes_measure, measure.attributes)

      stub_api_request("/admin/green_lanes/measures/#{measure.id}", :delete)
        .and_return webmock_response :no_content
    end

    context "with category assessment edit" do
      let(:make_request) { delete green_lanes_measure_path(measure, category_assessment_id: "10") }

      it { is_expected.to redirect_to edit_green_lanes_category_assessment_path(id: "10") }
    end

    context "with measure list" do
      let(:make_request) { delete green_lanes_measure_path(measure) }

      it { is_expected.to redirect_to green_lanes_measures_path }
    end
  end
end
