RSpec.describe GreenLanes::CategoryAssessmentExemption do
  subject(:category_assessment_exemption) { build :category_assessment_exemption }

  it { expect(described_class).to be_xi_only }

  it { is_expected.to respond_to :category_assessment_id }
  it { is_expected.to respond_to :exemption_id }

  it { is_expected.to have_attributes category_assessment_id: category_assessment_exemption.category_assessment_id }
  it { is_expected.to have_attributes exemption_id: category_assessment_exemption.exemption_id }

  describe "#add_exemption" do
    subject(:add_exemption) { category_assessment_exemption.add_exemption }

    before do
      stub_api_request("/admin/green_lanes/category_assessments/#{category_assessment_exemption.category_assessment_id}/exemptions", :post, backend: "xi").to_return \
        webmock_response(:success)
    end

    it { expect(add_exemption.status).to eq(200) }
  end

  describe "#remove_exemption" do
    subject(:remove_exemption) { category_assessment_exemption.remove_exemption }

    before do
      stub_api_request("/admin/green_lanes/category_assessments/#{category_assessment_exemption.category_assessment_id}/exemptions?exemption_id=5", :delete, backend: "xi").to_return \
        webmock_response(:success)
    end

    it { expect(remove_exemption.status).to eq(200) }
  end
end
