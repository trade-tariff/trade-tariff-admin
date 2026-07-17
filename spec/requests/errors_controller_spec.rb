RSpec.describe ErrorsController do
  subject(:rendered_page) do
    make_request
    response
  end

  let(:body) { rendered_page.body }
  let(:json_response) { rendered_page.parsed_body }

  shared_examples "an error response" do |status, html_message, response_message|
    context "with an HTML request" do
      let(:make_request) { get path, headers: { "Accept" => "text/html" } }

      it "renders the HTML error", :aggregate_failures do
        expect(rendered_page).to have_http_status(status)
        expect(body).to include(html_message)
      end
    end

    context "with a JSON request" do
      let(:make_request) { get path, headers: { "Accept" => "application/json" } }

      it "renders the JSON error", :aggregate_failures do
        expect(rendered_page).to have_http_status(status)
        expect(json_response).to eq("error" => response_message)
      end
    end

    context "with another request format" do
      let(:make_request) { get path, headers: { "Accept" => "text/plain" } }

      it "renders the plain-text error", :aggregate_failures do
        expect(rendered_page).to have_http_status(status)
        expect(body).to eq(response_message)
      end
    end
  end

  describe "GET #bad_request" do
    let(:path) { "/400" }

    it_behaves_like "an error response", :bad_request, "Bad request", "Bad request"
  end

  describe "GET #not_found" do
    let(:path) { "/404" }

    it_behaves_like "an error response", :not_found, "Page not found", "Resource not found"
  end

  describe "GET #method_not_allowed" do
    let(:path) { "/405" }

    it_behaves_like "an error response", :method_not_allowed, "Method not allowed", "Method not allowed"
  end

  describe "GET #not_acceptable" do
    let(:path) { "/406" }

    it_behaves_like "an error response", :not_acceptable, "Not acceptable", "Not acceptable"
  end

  describe "GET #unprocessable_content" do
    let(:path) { "/422" }

    it_behaves_like "an error response", :unprocessable_content, "Unprocessable content", "Unprocessable content"
  end

  describe "GET #internal_server_error" do
    let(:path) { "/500" }

    it_behaves_like "an error response",
                    :internal_server_error,
                    "We are experiencing technical difficulties",
                    "Internal server error"
  end

  describe "GET #not_implemented" do
    let(:path) { "/501" }

    it_behaves_like "an error response", :not_implemented, "Not implemented", "Not implemented"
  end
end
