module TradeTariffAdmin
  module ServiceChooser
    class << self
      def xi_host
        service_choices["xi"]
      end

      def uk_host
        service_choices["uk"]
      end

      def service_default
        ENV.fetch("SERVICE_DEFAULT", "uk")
      end

      def service_choices
        @service_choices ||= JSON.parse(ENV.fetch("API_SERVICE_BACKEND_URL_OPTIONS", "{}"))
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

      def api_client(forced_service = nil)
        return Rails.application.config.public_send("http_client_#{forced_service}") if forced_service
        return Rails.application.config.http_client_xi if xi?

        Rails.application.config.http_client_uk
      end

      def uk?
        (service_choice || service_default) == "uk"
      end

      def xi?
        service_choice == "xi"
      end
    end
  end
end
