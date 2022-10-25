require_relative '../../json_api_parser'

module Her
  module Middleware
    class TariffJsonapiParser < ParseJSON
      def parse(body)
        json = parse_json(body)

        {
          data: JsonapiParser.new(json).parse,
          errors: json[:errors] || [],
          metadata: json[:meta] || {},
        }
      end

      def on_complete(env)
        env[:body] = case env[:status]
                     when 204
                       {
                         data: {},
                         errors: [],
                         metadata: {},
                       }
                     else
                       parse(env[:body])
                     end
      end
    end
  end
end
