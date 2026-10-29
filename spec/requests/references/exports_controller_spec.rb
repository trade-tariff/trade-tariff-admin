RSpec.describe References::ExportsController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }
  let(:csv) { "Search reference ID,Title\n1,gift\n" }
  let(:make_request) { get download_references_export_path }

  describe "GET #download" do
    include_context "with UK service"

    let(:make_request) { get "/uk/search_references/export/download" }

    before do
      stub_api_request("/search_references/export").with(query: { include_ai_labels: "false" }).to_return(
        status: 200,
        headers: { "content-type" => "text/csv" },
        body: csv,
      )
    end

    it { is_expected.to have_http_status(:ok) }

    it "sends the CSV as an attachment", :aggregate_failures do
      expect(rendered_page.media_type).to eq("text/csv")
      expect(rendered_page.headers["Content-Disposition"]).to match(/attachment; filename="search_references_\w+_\d{4}_\d{2}_\d{2}\.csv"/)
      expect(rendered_page.body).to eq(csv)
    end
  end

  %w[UK XI].each do |service|
    context "with #{service} service" do
      include_context "with #{service} service"

      %i[technical_operator superadmin hmrc_admin auditor guest].each do |role|
        context "when the user is #{role}" do
          let(:current_user) { create(:user, role) }
          let(:export_request) do
            stub_api_request("/search_references/export").with(query: { include_ai_labels: "false" }).to_return(
              status: 200,
              headers: { "content-type" => "text/csv" },
              body: csv,
            )
          end

          before { export_request }

          if %i[technical_operator superadmin hmrc_admin].include?(role)
            it "allows the export page", :aggregate_failures do
              get "/#{service.downcase}/search_references/export"

              expect(response).to have_http_status(:ok)
              expect(Capybara.string(response.body)).to have_button("Download search references")
            end

            it "allows the CSV download", :aggregate_failures do
              get "/#{service.downcase}/search_references/export/download"

              expect(response).to have_http_status(:ok)
              expect(response.body).to eq(csv)
            end

            if role == :superadmin
              it "shows the AI labels checkbox unchecked" do
                get "/#{service.downcase}/search_references/export"

                expect(Capybara.string(response.body)).to have_unchecked_field("Include AI-generated labels", name: "include_ai_labels")
              end
            else
              it "does not show the AI labels checkbox" do
                get "/#{service.downcase}/search_references/export"

                expect(Capybara.string(response.body)).not_to have_field("Include AI-generated labels")
              end

              it "rejects a request to include AI labels without calling the backend", :aggregate_failures do
                get "/#{service.downcase}/search_references/export/download", params: { include_ai_labels: "1" }

                expect(response).to have_http_status(:forbidden)
                expect(export_request).not_to have_been_requested
              end
            end
          else
            it "denies the export page" do
              get "/#{service.downcase}/search_references/export"

              expect(response).to have_http_status(:forbidden)
            end

            it "denies the CSV download without calling the backend", :aggregate_failures do
              get "/#{service.downcase}/search_references/export/download"

              expect(response).to have_http_status(:forbidden)
              expect(export_request).not_to have_been_requested
            end
          end
        end
      end
    end
  end

  describe "GET #download with AI label options as a superadmin" do
    let(:current_user) { create(:user, :superadmin) }

    %w[UK XI].each do |service|
      context "with #{service} service" do
        include_context "with #{service} service"

        { "1" => "true", "0" => "false", "true" => "true", "false" => "false" }.each do |value, expected|
          it "forwards include_ai_labels=#{value} as #{expected}", :aggregate_failures do
            export_request = stub_api_request("/search_references/export")
              .with(query: { include_ai_labels: expected }).to_return(status: 200, body: csv)

            get "/#{service.downcase}/search_references/export/download", params: { include_ai_labels: value }

            expect(response).to have_http_status(:ok)
            expect(export_request).to have_been_requested.once
          end
        end
      end
    end
  end

  describe "GET #download when the backend fails" do
    before do
      stub_api_request("/search_references/export").with(query: { include_ai_labels: "false" }).to_return(status: 500, body: "")
    end

    it { is_expected.to redirect_to(references_export_path) }

    it "shows a failure message" do
      rendered_page
      expect(flash[:alert]).to eq("Search references export failed")
    end
  end

  describe "the export page" do
    let(:make_request) { get references_export_path }

    it "shows a form to download the CSV", :aggregate_failures do
      rendered_page
      expect(Capybara.string(response.body)).to have_button("Download search references")
      expect(Capybara.string(response.body)).to have_css('form[action="/search_references/export/download"][method="get"]')
    end
  end
end
