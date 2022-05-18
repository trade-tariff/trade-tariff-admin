module FaradayMiddleware
  class ServiceUrls < Faraday::Middleware
    def call(env)
      service_uri = URI(TradeTariffAdmin::ServiceChooser.api_host)
      env.url.host = service_uri.host
      env.url.port = service_uri.port
      @app.call(env)
    end
  end
end
