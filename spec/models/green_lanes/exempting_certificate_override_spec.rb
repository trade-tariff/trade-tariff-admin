require 'rails_helper'

RSpec.describe GreenLanes::ExemptingCertificateOverride do
  subject(:exempting_certificate_override) { build :exempting_certificate_override }

  it { expect(described_class).to be_xi_only }

  it { is_expected.to respond_to :id }
  it { is_expected.to respond_to :certificate_type_code }
  it { is_expected.to respond_to :certificate_code }
  it { is_expected.to respond_to :created_at }
  it { is_expected.to respond_to :updated_at }

  it { is_expected.to have_attributes id: exempting_certificate_override.id }
  it { is_expected.to have_attributes certificate_type_code: exempting_certificate_override.certificate_type_code }
  it { is_expected.to have_attributes certificate_code: exempting_certificate_override.certificate_code }
  it { is_expected.to have_attributes created_at: exempting_certificate_override.created_at }
  it { is_expected.to have_attributes updated_at: exempting_certificate_override.updated_at }

  describe '#all' do
    subject { described_class.all }

    before do
      allow(TradeTariffAdmin::ServiceChooser).to \
        receive(:service_choice).and_return service_choice

      stub_api_request('/admin/green_lanes/exempting_certificate_overrides', backend: 'xi').to_return \
        jsonapi_response(:exempting_certificate_override, attributes_for_list(:exempting_certificate_override, 2))
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
