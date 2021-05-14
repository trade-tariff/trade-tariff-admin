require 'rails_helper'

# rubocop:disable RSpec/MultipleExpectations
describe RoutingFilter::ServicePathPrefixHandler, type: :routing do
  let(:path) { "#{prefix}/rollbacks" }

  after do
    Thread.current[:service_choice] = nil
  end

  describe 'matching routes' do
    context 'when the service choice prefix is xi' do
      let(:prefix) { '/xi' }

      it 'sets the request params service choice to the xi backend' do
        expect(get: path).to route_to(
          controller: 'rollbacks',
          action: 'index',
        )
        expect(Thread.current[:service_choice]).to eq('xi')
      end
    end

    context 'when the service choice prefix is not present' do
      let(:prefix) { nil }

      it 'does not specify the service backend' do
        expect(get: path).to route_to(
          controller: 'rollbacks',
          action: 'index',
        )
        expect(Thread.current[:service_choice]).to be_nil
      end
    end

    context 'when the service choice prefix is the same as the default' do
      let(:prefix) { '/uk' }

      it 'does not set the request params service choice' do
        expect(get: path).to route_to(
          controller: 'rollbacks',
          action: 'index',
        )
        expect(Thread.current[:service_choice]).to eq('uk')
      end
    end

    context 'when the service choice prefix is set to an unsupported service choice' do
      let(:prefix) { '/xixi' }

      it 'routes to a not_found action in the errors controller' do
        expect(get: path).not_to be_routable
        expect(Thread.current[:service_choice]).to eq(nil)
      end
    end
  end

  describe 'path generation' do
    before do
      TradeTariffAdmin::ServiceChooser.service_choice = choice
    end

    context 'when the service choice is not the default' do
      let(:choice) { 'xi' }

      it 'prepends the choice to the url' do
        result = new_rollback_url(page: '1')

        expect(result).to eq('http://test.host/xi/rollbacks/new?page=1')
      end

      it 'prepends the choice to the path' do
        result = new_rollback_path(page: '1')

        expect(result).to eq('/xi/rollbacks/new?page=1')
      end
    end

    context 'when the service choice is the default' do
      let(:choice) { 'uk' }

      it 'does not prepend the choice to the url' do
        result = new_rollback_url(page: '1')

        expect(result).to eq('http://test.host/rollbacks/new?page=1')
      end

      it 'does not prepend the choice to the path' do
        result = new_rollback_path(page: '1')

        expect(result).to eq('/rollbacks/new?page=1')
      end
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
