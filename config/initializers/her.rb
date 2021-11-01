require 'faraday_middleware/service_urls'

# order of used middleware matters: first used last executed
Her::API.setup url: Rails.application.config.api_host do |c|
  # Request
  c.use FaradayMiddleware::ServiceUrls
  c.use Faraday::Request::UrlEncoded
  c.use Her::Middleware::BearerTokenAuthentication, ENV['BEARER_TOKEN'] || 'tariff-api-test-token'

  # Response
  c.use Her::Middleware::HeaderMetadataParse
  c.use Her::Middleware::TariffJsonapiParser
  c.use Faraday::Response::RaiseError

  # Adapter
  c.adapter Faraday::Adapter::NetHttp
end

Her::UK_API = Her::API.new
Her::UK_API.setup url: TradeTariffAdmin::ServiceChooser.service_choices['uk'] do |c|
  # Request
  c.use Faraday::Request::UrlEncoded
  c.use Her::Middleware::BearerTokenAuthentication, ENV['BEARER_TOKEN'] || 'tariff-api-test-token'

  # Response
  c.use Her::Middleware::HeaderMetadataParse
  c.use Her::Middleware::TariffJsonapiParser
  c.use Faraday::Response::RaiseError

  # Adapter
  c.adapter Faraday::Adapter::NetHttp
end
