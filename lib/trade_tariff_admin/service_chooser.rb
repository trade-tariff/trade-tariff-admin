module TradeTariffAdmin
  module ServiceChooser
    class << self
      def service_default
        ENV.fetch('SERVICE_DEFAULT', 'uk')
      end

      def service_choices
        @service_choices ||= JSON.parse(ENV.fetch('API_SERVICE_BACKEND_URL_OPTIONS', '{}'))
      end

      def service_choice=(service_choice)
        Thread.current[:service_choice] = service_choice
      end

      def service_choice
        Thread.current[:service_choice]
      end

      def service_name
        service_choice || service_default
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
