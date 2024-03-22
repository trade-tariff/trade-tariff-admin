require 'faraday_middleware/service_urls'
require 'her/model/propagate_errors'

Her::Model.include(Her::Model::PropagateErrors)

api_host = ENV['TARIFF_API_HOST'].presence || Plek.new.find('tariff-api')

# order of used middleware matters: first used last executed
Her::API.setup url: api_host do |c|
  # Request
  c.use FaradayMiddleware::ServiceUrls
  c.use Faraday::Request::UrlEncoded
  c.use FaradayMiddleware::BearerTokenAuthentication, ENV['BEARER_TOKEN'] || 'tariff-api-test-token'

  # Response
  c.use Her::Middleware::HeaderMetadataParse
  c.use Her::Middleware::TariffJsonapiParser
  c.use Her::Middleware::RaiseError

  # Adapter
  c.adapter Faraday::Adapter::NetHttp
end

Her::UK_API = Her::API.new
Her::UK_API.setup url: TradeTariffAdmin::ServiceChooser.service_choices['uk'] do |c|
  # Request
  c.use Faraday::Request::UrlEncoded
  c.use FaradayMiddleware::BearerTokenAuthentication, ENV['BEARER_TOKEN'] || 'tariff-api-test-token'

  # Response
  c.use Her::Middleware::HeaderMetadataParse
  c.use Her::Middleware::TariffJsonapiParser
  c.use Her::Middleware::RaiseError

  # Adapter
  c.adapter Faraday::Adapter::NetHttp
end

Her::XI_API = Her::API.new
Her::XI_API.setup url: TradeTariffAdmin::ServiceChooser.service_choices['xi'] do |c|
  # Request
  c.use Faraday::Request::UrlEncoded
  c.use FaradayMiddleware::BearerTokenAuthentication, ENV['BEARER_TOKEN'] || 'tariff-api-test-token'

  # Response
  c.use Her::Middleware::HeaderMetadataParse
  c.use Her::Middleware::TariffJsonapiParser
  c.use Her::Middleware::RaiseError

  # Adapter
  c.adapter Faraday::Adapter::NetHttp
end
