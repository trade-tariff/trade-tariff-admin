RSpec.describe QuotasController do
  describe 'GET #new' do
    subject(:do_request) do
      create(:user, :hmrc_editor)

      get quota_search_quotas_path

      response
    end

    it { is_expected.to render_template(:new) }
  end

  describe 'GET #search' do
    subject(:do_request) do
      get perform_search_quotas_path(quota_search: { order_number: quota_definition.quota_order_number_id })

      response
    end

    before do
      create(:user, :hmrc_editor)
      allow(QuotaOrderNumbers::QuotaDefinition).to receive(:find).and_return(quota_definition)
    end

    let(:quota_definition) { build(:quota_definition, :with_quota_balance_events) }

    it 'fetches the quota definition' do
      do_request

      expect(QuotaOrderNumbers::QuotaDefinition).to have_received(:find).with(quota_definition.quota_order_number_id)
    end

    it { is_expected.to render_template(:search) }
  end
end
