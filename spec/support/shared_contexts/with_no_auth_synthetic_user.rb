RSpec.shared_context "with no-auth synthetic user" do
  let(:current_user) { User.basic_auth_user! }

  before do
    allow(TradeTariffAdmin).to receive_messages(
      authenticate_with_passwordless?: false,
      basic_session_authentication?: false,
      no_authentication?: true,
    )
  end
end
