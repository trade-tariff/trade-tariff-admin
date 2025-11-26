module AuthStrategySpecHelper
  def expect_unauthenticated_redirect(make_request)
    warn "DEBUG auth_strategy=#{TradeTariffAdmin.auth_strategy}"
    make_request.call

    expect(response).to redirect_to(TradeTariffAdmin.identity_consumer_url)
  end
end

RSpec.configure do |config|
  config.include AuthStrategySpecHelper, type: :request
end
