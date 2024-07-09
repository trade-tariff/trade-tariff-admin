require 'rails_helper'

RSpec.describe GreenLanes::ExemptingAdditionalCodeOverride do
  subject(:exempting_additional_code_override) { build :exempting_additional_code_override }

  it { is_expected.to respond_to :id }
  it { is_expected.to respond_to :additional_code_type_id }
  it { is_expected.to respond_to :additional_code }
  it { is_expected.to respond_to :created_at }
  it { is_expected.to respond_to :updated_at }

  it { is_expected.to have_attributes id: exempting_additional_code_override.id }
  it { is_expected.to have_attributes additional_code_type_id: exempting_additional_code_override.additional_code_type_id }
  it { is_expected.to have_attributes additional_code: exempting_additional_code_override.additional_code }
  it { is_expected.to have_attributes created_at: exempting_additional_code_override.created_at }
  it { is_expected.to have_attributes updated_at: exempting_additional_code_override.updated_at }

  describe '#all' do
    subject { described_class.all }

    before do
      allow(TradeTariffAdmin::ServiceChooser).to \
        receive(:service_choice).and_return service_choice

      stub_api_request('/admin/green_lanes/exempting_additional_code_overrides', backend: 'xi').to_return \
        jsonapi_response(:exempting_additional_code_override, attributes_for_list(:exempting_additional_code_override, 2))
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
