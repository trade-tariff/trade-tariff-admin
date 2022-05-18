class Report
  FILENAME_REGEX = /\A.*filename=(?<filename>.*\.csv)\Z/

  attr_reader :csv_data, :filename

  def initialize(csv_data, filename)
    @csv_data = csv_data
    @filename = filename
  end

  class << self
    def build(resource)
      path = "/admin/#{resource}.csv"

      csv_response = csv_api_client.get(path)
      csv_data = csv_response.body
      filename = csv_response.env.response_headers['content-disposition'].match(FILENAME_REGEX)[:filename]

      new(csv_data, filename)
    end

    private

    def csv_api_client
      @csv_api_client ||= Faraday.new(TradeTariffAdmin::ServiceChooser.api_host) do |conn|
        conn.use FaradayMiddleware::AcceptApiV2
        conn.use FaradayMiddleware::BearerTokenAuthentication, ENV['BEARER_TOKEN'] || 'tariff-api-test-token'
        conn.use Faraday::Response::RaiseError
        conn.use FaradayMiddleware::ServiceUrls

        conn.response :logger if ENV['DEBUG_REQUESTS']
      end
    end
  end
end
