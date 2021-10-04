module ApiResponsesHelper
  def stub_api_for(klass, &block)
    klass.use_api(api = Her::API.new)

    api.setup url: Rails.application.config.api_host do |c|
      c.use Her::Middleware::HeaderMetadataParse # lib/her/middleware/header_metadata_parse.rb
      c.use Her::Middleware::AcceptApiV2         # lib/her/middleware/accept_api_v2.rb
      c.use Her::Middleware::TariffJsonapiParser # lib/her/middleware/tariff_jsonapi_parser.rb
      c.adapter(:test, &block)
    end
  end

  def api_success_response(response = {}, headers = {})
    [200, headers, response.to_json]
  end

  def jsonapi_success_response(type, response = {}, headers = {})
    formatted_response = format_json_api_response(type, response)

    [200, headers, formatted_response.to_json]
  end

  def api_created_response(body = {}, headers = {})
    api_response(201, headers, body)
  end

  def api_updated_response(resource_url)
    api_success_response({}, location: resource_url)
  end

  def api_no_content_response(body = {}, headers = {})
    api_response(204, headers, body)
  end

  def api_error_response(errors, headers = {})
    api_response(422, headers, errors)
  end

  def api_response(status, headers, body)
    [status, headers, body.to_json]
  end

  def format_json_api_response(type, response)
    case response
    when Hash
      {
        data: format_json_api_item(type, response),
      }
    when Array
      {
        data: response.map { |r| format_json_api_item(type, r) },
      }
    else
      response
    end
  end

  def format_json_api_item(type, attributes)
    {
      type: type,
      attributes: attributes,
    }
  end
end
