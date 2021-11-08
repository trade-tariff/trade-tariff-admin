require 'rails_helper'

RSpec.describe ServiceHelper, type: :helper do
  before do
    allow(TradeTariffAdmin::ServiceChooser).to receive(:service_choice).and_return(choice)
  end

  describe '.switch_service_link' do
    let(:request) { double('request', filtered_path: path) }

    before do
      allow(helper).to receive(:request).and_return(request)
    end

    context 'when the selected service choice is nil' do
      let(:path) { '/rollbacks/new' }
      let(:choice) { nil }

      it 'returns the link to the XI service' do
        expect(switch_service_link).to eq(link_to('Switch to XI service', '/xi/rollbacks/new'))
      end
    end

    context 'when the selected service choice is uk' do
      let(:path) { '/uk/rollbacks/new' }
      let(:choice) { 'uk' }

      it 'returns the link to the XI service' do
        expect(switch_service_link).to eq(link_to('Switch to XI service', '/xi/rollbacks/new'))
      end
    end

    context 'when the selected service choice is xi' do
      let(:path) { '/xi/rollbacks/new' }
      let(:choice) { 'xi' }

      it 'returns the link to the current UK service' do
        expect(switch_service_link).to eq(link_to('Switch to UK service', '/rollbacks/new'))
      end

      context 'when using the root path' do
        let(:path) { '/xi' }
        let(:choice) { 'xi' }

        it 'returns the link to the current UK service' do
          expect(switch_service_link).to eq(link_to('Switch to UK service', '/'))
        end
      end
    end

    context 'with a css class' do
      subject { switch_service_link class: 'test-class' }

      let(:path) { '/rollbacks/new' }
      let(:choice) { nil }

      it { is_expected.to have_css 'a.test-class' }
    end
  end
end
