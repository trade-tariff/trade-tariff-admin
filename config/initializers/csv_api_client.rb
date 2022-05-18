require 'trade_tariff_admin'

Rails.application.config.csv_api_client = Faraday.new(TradeTariffAdmin::ServiceChooser.api_host) do |conn|
  conn.use FaradayMiddleware::AcceptApiV2
  conn.use FaradayMiddleware::BearerTokenAuthentication, ENV['BEARER_TOKEN']
  conn.use Faraday::Response::RaiseError
  conn.use FaradayMiddleware::ServiceUrls

  conn.response :logger if ENV['DEBUG_REQUESTS']
end
