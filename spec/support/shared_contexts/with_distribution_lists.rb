RSpec.shared_context "with distribution lists" do
  let(:cognito_client) { Aws::CognitoIdentityProvider::Client.new(stub_responses: true, region: "eu-west-2") }
  let(:recipient_sub) { "11111111-2222-3333-4444-555555555555" }
  let(:recipient_email) { "jane.recipient@example.com" }

  before do
    allow(TradeTariffAdmin).to receive(:cognito_user_pool_id).and_return("eu-west-2_pool")
    allow(Aws::CognitoIdentityProvider::Client).to receive(:new).and_return(cognito_client)

    cognito_client.stub_responses(:list_groups, groups: [
      { group_name: "admin" },
      { group_name: "myott" },
      { group_name: "portal" },
      { group_name: "dl-tariff-notifications", description: "Tariff notifications" },
    ])
    cognito_client.stub_responses(:list_users_in_group, users: [
      {
        username: recipient_sub,
        user_status: "CONFIRMED",
        enabled: true,
        attributes: [{ name: "email", value: recipient_email }],
      },
    ])
    cognito_client.stub_responses(:admin_list_groups_for_user, groups: [
      { group_name: "dl-tariff-notifications" },
      { group_name: "myott" },
    ])
  end

  def cognito_requests(operation)
    cognito_client.api_requests.select { |request| request[:operation_name] == operation }
  end
end
