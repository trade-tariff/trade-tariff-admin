module ApiResponsesHelper
  def stub_api_for(klass, &block)
    klass.use_api(api = Her::API.new)

    api.setup url: ENV['TARIFF_API_HOST'] do |c|
      c.use FaradayMiddleware::AcceptApiV2
      c.use Her::Middleware::HeaderMetadataParse
      c.use Her::Middleware::TariffJsonapiParser

      c.adapter(:test, &block)
    end
  end

  def api_success_response(response = {}, headers = {})
    [200, headers, response.to_json]
  end

  def jsonapi_success_response(type, response = {}, headers = {})
    formatted_response = format_jsonapi_response(type, response)

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
    api_response(422,
                 headers.reverse_merge('content-type' => 'application/json'),
                 format_jsonapi_errors(errors))
  end

  def api_response(status, headers, body)
    [status, headers, body.to_json]
  end

  def format_jsonapi_response(type, response)
    case response
    when Hash
      {
        data: format_jsonapi_item(type, response),
      }
    when Array
      {
        data: response.map { |r| format_jsonapi_item(type, r) },
        meta: {
          pagination: {
            page: 1,
            per_page: response.length,
            total_count: response.length * 5,
          },
        },
      }
    else
      response
    end
  end

  def format_jsonapi_item(type, attributes)
    {
      type:,
      attributes:,
    }
  end

  def format_jsonapi_errors(errors)
    {
      errors: errors.map do |attribute, error|
        {
          status: 422,
          title: error,
          detail: "#{attribute.to_s.humanize} #{error}",
          source: {
            pointer: "/data/attributes/#{attribute}",
          },
        }
      end,
    }
  end

  # Wrapper around WebMock's stub_request with defaults that apply to all our api requests
  def stub_api_request(endpoint, method = :get, backend: nil)
    backend_url = if backend
                    TradeTariffAdmin::ServiceChooser.service_choices[backend]
                  else
                    TradeTariffAdmin::ServiceChooser.api_host
                  end

    endpoint = "/#{endpoint}" unless endpoint.starts_with?('/')
    endpoint = "/admin#{endpoint}" unless endpoint.starts_with?('/admin/')
    url = "#{backend_url}#{endpoint}"

    stub_request(method, url)
  end

  # Generate a JSONAPI response from data suitable for webmock
  def jsonapi_response(type, response_data, status: 200, headers: nil)
    {
      status:,
      headers: headers || { 'content-type' => 'application/json; charset=utf-8' },
      body: format_jsonapi_response(type, response_data).to_json,
    }
  end

  # Wrapper around the existing api response helpers to allow them to work with
  # with WebMock
  def webmock_response(response_type, *args)
    response_data = send(:"api_#{response_type}_response", *args)

    {
      status: response_data[0],
      headers: response_data[1],
      body: response_data[2],
    }
  end
end
