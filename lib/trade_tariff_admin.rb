# TODO: Remove these and autoload from lib correctly
require 'faraday_middleware/accept_api_v2'
require 'faraday_middleware/bearer_token_authentication'
require 'faraday_middleware/service_urls'
require 'her/middleware/raise_error'
require 'her/middleware/header_metadata_parse'
require 'her/middleware/tariff_jsonapi_parser'

require_relative './trade_tariff_admin'

module TradeTariffAdmin
  class << self
    def host
      ENV.fetch('ADMIN_HOST', 'http://localhost')
    end

    def production?
      ENV['GOVUK_APP_DOMAIN'] == 'tariff-admin-production.cloudapps.digital'
    end
  end
end
