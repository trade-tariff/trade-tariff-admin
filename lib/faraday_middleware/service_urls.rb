require 'faraday'

module FaradayMiddleware
  class ServiceUrls < Faraday::Middleware
    def call(env)
      env.url.host = service_uri.host
      env.url.port = service_uri.port
      @app.call(env)
    end

    private

    def service_uri
      @service_uri ||= URI(TradeTariffAdmin::ServiceChooser.api_host)
    end
  end
end
