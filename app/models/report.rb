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

      csv_response = Rails.application.config.csv_api_client.get(path)
      csv_data = csv_response.body
      filename = csv_response.env.response_headers['content-disposition'].match(FILENAME_REGEX)[:filename]

      new(csv_data, filename)
    end
  end
end
