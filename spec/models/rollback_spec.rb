require 'rails_helper'

RSpec.describe Rollback do
  describe '#valid?' do
    before do
      allow(TradeTariffAdmin::ServiceChooser).to receive(:service_name).and_return('uk')
    end

    context 'when service is confirmed correctly' do
      let(:rollback) { build :rollback, confirm_service: 'uk' }

      it 'is valid' do
        rollback.valid?

        expect(rollback.errors).to be_empty
      end
    end

    context 'when service is NOT confirmed correctly' do
      let(:rollback) { build :rollback, confirm_service: 'xi' }

      it 'is invalid' do
        rollback.valid?

        expect(rollback.errors).to include(:confirm_service)
      end
    end
  end
end
