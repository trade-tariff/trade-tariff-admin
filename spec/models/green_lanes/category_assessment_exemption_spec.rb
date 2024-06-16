require 'rails_helper'

RSpec.describe GreenLanes::CategoryAssessmentExemption do
  subject(:category_assessment_exemption) { build :category_assessment_exemption }

  it { is_expected.to respond_to :category_assessment_id }
  it { is_expected.to respond_to :exemption_id }

  it { is_expected.to have_attributes category_assessment_id: category_assessment_exemption.category_assessment_id }
  it { is_expected.to have_attributes exemption_id: category_assessment_exemption.exemption_id }

  describe '#add_exemption' do
    subject { category_assessment_exemption.add_exemption }

    before do
      stub_api_request("/admin/green_lanes/category_assessments/#{category_assessment_exemption.category_assessment_id}/exemptions", :post, backend: 'xi').to_return \
        webmock_response(:success)
    end

    context 'when exemption added' do

      it 'expect success status' do
        expect(subject[:response].status).to eq(200)
      end
    end
  end
end
