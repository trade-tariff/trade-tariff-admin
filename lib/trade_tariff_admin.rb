# TODO: Remove these and autoload from lib correctly
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

    def authenticate_with_sso?
      @authenticate_with_sso ||= ENV.fetch('AUTHENTICATE_WITH_SSO', 'true') == 'true'
    end

    def basic_authentication?
      @basic_authentication ||= !authenticate_with_sso? && basic_password.present?
    end

    def basic_password
      @basic_password ||= ENV['BASIC_PASSWORD']
    end
  end
end
