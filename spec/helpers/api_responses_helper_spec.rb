require "rails_helper"
require "net/http"

RSpec.describe ApiResponsesHelper do
  describe "#stub_api_request" do
    before do
      TradeTariffAdmin::ServiceChooser.service_choice = "xi"
    end

    it "defaults to the active service choice" do
      stub_api_request("/green_lanes/example").to_return(status: 200, body: "ok")

      response = Net::HTTP.get_response(URI("http://localhost:3019/admin/green_lanes/example"))

      expect(response).to have_attributes(code: "200", body: "ok")
    end
  end
end
