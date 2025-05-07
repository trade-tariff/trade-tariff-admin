module ApiResponsesHelper
  def api_success_response(response = {}, headers = {})
    {
      status: 200,
      headers: headers,
      body: response.to_json,
    }
  end

  def jsonapi_success_response(type, response = {}, headers = {})
    formatted_response = format_jsonapi_response(type, response)

    {
      status: 200,
      headers: headers,
      body: formatted_response.to_json,
    }
  end

  def api_created_response(body = {}, headers = {})
    {
      status: 201,
      headers: headers,
      body: body.to_json,
    }
  end

  def api_updated_response(resource_url)
    {
      status: 200,
      headers: { 'location' => resource_url },
      body: {}.to_json,
    }
  end

  def api_no_content_response(headers = {})
    {
      status: 204,
      headers: headers,
      body: nil,
    }
  end

  def api_error_response(errors, headers = {})
    {
      status: 422,
      headers: headers.reverse_merge('content-type' => 'application/json'),
      body: format_jsonapi_errors(errors).to_json,
    }
  end

  def api_response(status, headers, body)
    {
      status: status,
      headers: headers,
      body: body.to_json,
    }
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
    send(:"api_#{response_type}_response", *args)
  end
end
