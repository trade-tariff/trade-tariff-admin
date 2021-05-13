require 'her/middleware/bearer_token_authentication'
require 'her/middleware/header_metadata_parse'
require 'her/middleware/accept_api_v2'
require 'her/middleware/tariff_jsonapi_parser'
require 'redis_resolver'

module TradeTariffAdmin
  class << self
    def host
      ENV.fetch('ADMIN_HOST', 'http://localhost')
    end

    def production?
      ENV['GOVUK_APP_DOMAIN'] == 'tariff-admin-production.cloudapps.digital'
    end
  end

  module ServiceChooser
    class << self
      def service_default
        ENV.fetch('SERVICE_DEFAULT', 'uk')
      end

      def service_choices
        @service_choices ||= JSON.parse(ENV['API_SERVICE_BACKEND_URL_OPTIONS'])
      end

      def service_choice=(service_choice)
        Thread.current[:service_choice] = service_choice
      end

      def service_choice
        Thread.current[:service_choice]
      end

      def api_host
        host = service_choices[service_choice]

        return service_choices[service_default] if host.blank?

        host
      end

      def uk?
        (service_choice || service_default) == 'uk'
      end

      def xi?
        service_choice == 'xi'
      end
    end
  end
end
