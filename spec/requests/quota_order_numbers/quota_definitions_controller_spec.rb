RSpec.describe QuotaOrderNumbers::QuotaDefinitionsController do
  subject(:do_request) do
    create(:user, :hmrc_editor)

    stubbed_response = jsonapi_response(:quota_definition, attributes_for(:quota_definition))
    stub_api_request('/quota_order_numbers/051822/quota_definitions/current')
      .and_return(stubbed_response)

    post quota_definitions_current_quota_order_number_path('051822')

    response
  end

  let(:create_user) {}

  describe 'GET #current' do
    let(:make_request) {}
  end
end
