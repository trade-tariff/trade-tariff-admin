module Her
  module Middleware
    # RaiseError derives from the Faraday RaiseError middleware
    # but accepts certain status codes we know how to parse
    class RaiseError < ::Faraday::Response::RaiseError
      ERRORS_TO_PARSE = [
        400, # Bad request
        409, # Conflict
        422, # Unprocessable entity
      ].freeze

      def on_complete(env)
        return super unless ERRORS_TO_PARSE.include?(env[:status])

        content_type_key = env[:response_headers].keys.find { |h| h.match?(/\Acontent-type\z/i) }
        unless content_type_key && env[:response_headers][content_type_key].match?(/json/)
          super
        end
      end
    end
  end
end
