module FaradayMiddleware
  class AcceptApiV2 < Faraday::Middleware
    def call(env)
      add_header(env[:request_headers])
      @app.call(env)
    end

    private

    def add_header(headers)
      headers.merge! 'Accept' => 'application/vnd.uktt.v2'
    end
  end
end
