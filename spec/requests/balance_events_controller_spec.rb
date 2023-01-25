RSpec.describe QuotasController do
  describe 'GET #show' do
    subject(:do_request) do
      get balance_event_path(quota_definition.quota_order_number_id)

      response
    end

    before do
      create(:user, :hmrc_editor)
      allow(QuotaOrderNumbers::QuotaDefinition).to receive(:by_quota_order_number).and_return(quota_definitions)
    end

    let(:quota_definitions) { [quota_definition, quota_definition] }
    let(:quota_definition) { build(:quota_definition, :with_quota_balance_events, 
                                                      :with_quota_order_number_origins,
                                                      :without_quota_critical_events, 
                                                      :without_quota_unsuspension_events, 
                                                      :without_quota_exhaustion_events, 
                                                      :without_quota_reopening_events, 
                                                      :without_quota_unblocking_events) }

    it 'fetches the quota definition' do
      do_request

      expect(QuotaOrderNumbers::QuotaDefinition).to have_received(:by_quota_order_number).with(quota_definition.quota_order_number_id)
    end

    it { is_expected.to render_template(:show) }
  end
end
