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

  # Adapter
  c.adapter Faraday::Adapter::NetHttp
end
