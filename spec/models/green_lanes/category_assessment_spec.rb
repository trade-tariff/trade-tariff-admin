require 'rails_helper'

RSpec.describe GreenLanes::CategoryAssessment do
  subject(:category_assessment) { build :category_assessment }

  it { is_expected.to respond_to :id }
  it { is_expected.to respond_to :measure_type_id }
  it { is_expected.to respond_to :regulation_id }
  it { is_expected.to respond_to :regulation_role }
  it { is_expected.to respond_to :theme_id }
  it { is_expected.to respond_to :created_at }
  it { is_expected.to respond_to :updated_at }

  it { is_expected.to have_attributes id: category_assessment.id }
  it { is_expected.to have_attributes measure_type_id: category_assessment.measure_type_id }
  it { is_expected.to have_attributes regulation_id: category_assessment.regulation_id }
  it { is_expected.to have_attributes regulation_role: category_assessment.regulation_role }
  it { is_expected.to have_attributes theme_id: category_assessment.theme_id }
  it { is_expected.to have_attributes created_at: category_assessment.created_at }
  it { is_expected.to have_attributes updated_at: category_assessment.updated_at }


  describe '#all' do
    subject { described_class.all }

    before do
      allow(TradeTariffAdmin::ServiceChooser).to \
        receive(:service_choice).and_return service_choice

      stub_api_request('/admin/category_assessments', backend: 'xi').to_return \
        jsonapi_response(:category_assessment, attributes_for_list(:category_assessment, 2))
    end

    context 'with UK service' do
      let(:service_choice) { 'uk' }

      it { is_expected.to have_attributes length: 2 }
    end

    context 'with XI service' do
      let(:service_choice) { 'xi' }

      it { is_expected.to have_attributes length: 2 }
    end
  end
end
