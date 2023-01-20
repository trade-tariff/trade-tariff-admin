RSpec.describe QuotasController do
  describe 'GET #new' do
    subject(:do_request) do
      create(:user, :hmrc_editor)

      get quota_search_path

      response
    end

    context 'when on uk service' do
      include_context 'with UK service'

      it { is_expected.to render_template(:new) }
    end

    context 'when on xi service' do
      include_context 'with XI service'

      it { is_expected.to render_template(:not_found) }
    end
  end

  describe 'GET #search' do
    subject(:do_request) do
      create(:user, :hmrc_editor)

      get perform_quota_search_path(quota_search: { order_number: quota_definition.quota_order_number_id })

      response
    end

    let(:quota_definitions) { [quota_definition, quota_definition] }
    let(:quota_definition) { build(:quota_definition, :with_quota_balance_events, :with_quota_order_number_origins) }

    before do
      create(:user, :hmrc_editor)

      allow(QuotaOrderNumbers::QuotaDefinition).to receive(:by_quota_order_number).and_return(quota_definitions)
    end

    context 'when on uk service' do
      include_context 'with UK service'

      let(:quota_definition) { build(:quota_definition, :with_quota_balance_events) }

      it 'fetches the quota definition' do
        do_request

        expect(QuotaOrderNumbers::QuotaDefinition).to have_received(:by_quota_order_number).with(quota_definition.quota_order_number_id)
      end

      it { is_expected.to render_template(:search) }
    end

    context 'when on xi service' do
      include_context 'with XI service'

      it { is_expected.to render_template(:not_found) }
    end
  end
end
