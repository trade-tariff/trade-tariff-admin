# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations, RSpec/MultipleMemoizedHelpers
RSpec.describe TariffKnowledgeSyntheticAtarsController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"
  include XlsxWorkbookHelper

  let(:current_user) { create(:user, :technical_operator) }
  let(:synthetic_atar_id) { "12" }
  let(:json_headers) { { "content-type" => "application/json; charset=utf-8" } }
  let(:synthetic_atar_attributes) do
    {
      "chapter" => "39",
      "real_user_search" => "plastic box",
      "times_searched" => 25,
      "likely_heading" => "3924",
      "description" => "Reusable plastic food storage box with a clip-on lid, made of polypropylene, for household use.",
      "goods_nomenclature_item_id" => "3924100000",
      "notes" => "Household tableware and kitchenware of plastics.",
      "completed_by" => "AB",
      "created_at" => "2026-09-25T10:30:00Z",
      "updated_at" => "2026-09-25T10:30:00Z",
    }
  end
  let(:synthetic_atar_response) do
    jsonapi_response("tariff_knowledge_synthetic_atar", synthetic_atar_attributes.merge("resource_id" => synthetic_atar_id))
  end
  let(:versions_response) do
    {
      status: 200,
      headers: json_headers,
      body: {
        data: [
          {
            id: "31",
            type: "version",
            attributes: {
              "item_type" => "TariffKnowledge::SyntheticAtar",
              "item_id" => synthetic_atar_id,
              "event" => "update",
              "whodunnit" => nil,
              "created_at" => "2026-09-25T11:00:00Z",
              "object" => synthetic_atar_attributes,
              "changeset" => { "changed_fields" => %w[notes], "changes" => { "notes" => { "type" => "simple", "old" => "Old note", "new" => "New note" } } },
            },
          },
          {
            id: "30",
            type: "version",
            attributes: {
              "item_type" => "TariffKnowledge::SyntheticAtar",
              "item_id" => synthetic_atar_id,
              "event" => "create",
              "whodunnit" => nil,
              "created_at" => "2026-09-25T10:30:00Z",
              "object" => synthetic_atar_attributes,
            },
          },
        ],
      }.to_json,
    }
  end

  def paginated_response(rows, total_count: rows.length)
    {
      status: 200,
      headers: json_headers,
      body: {
        data: rows.map { |attributes| { type: "tariff_knowledge_synthetic_atar", id: attributes["resource_id"], attributes: attributes.except("resource_id") } },
        meta: { pagination: { page: 1, per_page: 20, total_count: } },
      }.to_json,
    }
  end

  def stub_versions
    stub_api_request("/versions")
      .with(query: hash_including("item_type" => "TariffKnowledge::SyntheticAtar", "item_id" => synthetic_atar_id))
      .and_return(versions_response)
  end

  describe "GET #index" do
    let(:make_request) { get tariff_knowledge_synthetic_atars_path }

    before do
      stub_api_request("/tariff_knowledge_synthetic_atars")
        .and_return(paginated_response([synthetic_atar_attributes.merge("resource_id" => synthetic_atar_id)]))
    end

    it { is_expected.to have_http_status :success }

    it "lists the synthetic ATaRs" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h1", text: "Synthetic ATaRs")
      expect(page).to have_css("caption", text: "1 synthetic ATaR")
      expect(page).to have_link("plastic box", href: tariff_knowledge_synthetic_atar_path(synthetic_atar_id))
      expect(page).to have_css("td", text: "3924100000")
      expect(page).to have_css("td", text: "AB")
      expect(page).to have_link("New synthetic ATaR", href: new_tariff_knowledge_synthetic_atar_path)
    end

    context "with search and chapter filters" do
      let(:make_request) { get tariff_knowledge_synthetic_atars_path(q: "plastic", chapter: "39") }

      before do
        stub_api_request("/tariff_knowledge_synthetic_atars")
          .with(query: hash_including("q" => "plastic", "chapter" => "39"))
          .and_return(paginated_response([synthetic_atar_attributes.merge("resource_id" => synthetic_atar_id)]))
      end

      it "passes the filters to the backend and keeps them in the form" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_field("Search", with: "plastic")
        expect(page).to have_field("Chapter", with: "39")
        expect(page).to have_link("plastic box")
      end
    end

    context "when there are no synthetic ATaRs" do
      before do
        stub_api_request("/tariff_knowledge_synthetic_atars").and_return(paginated_response([]))
      end

      it "says so" do
        expect(rendered_page.body).to include("No synthetic ATaRs found.")
      end
    end

    context "when the backend cannot be reached" do
      before do
        stub_api_request("/tariff_knowledge_synthetic_atars").and_return(status: 400, headers: json_headers, body: { error: "bad request" }.to_json)
      end

      it "shows an empty list and a warning instead of an error page" do
        expect(rendered_page).to have_http_status(:success)
        expect(rendered_page.body).to include("Synthetic ATaRs could not be loaded. Try again.")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "GET #import" do
    let(:make_request) { get import_tariff_knowledge_synthetic_atars_path }

    it { is_expected.to have_http_status :success }

    it "explains the import and shows the upload form" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h1", text: "Import synthetic ATaRs")
      expect(page).to have_text("Classifications")
      expect(page).to have_text("Only rows with the status Done")
      expect(page).to have_link("Download an example file with the column headings", href: example_import_tariff_knowledge_synthetic_atars_path)
      expect(page).to have_field("Import file", type: "file")
      expect(page).to have_button("Import synthetic ATaRs")
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "GET #example_import" do
    let(:make_request) { get example_import_tariff_knowledge_synthetic_atars_path }

    it "downloads a CSV with only the column headings" do
      expect(rendered_page).to have_http_status(:success)
      expect(rendered_page.headers["Content-Type"]).to include("text/csv")
      expect(rendered_page.body).to eq("Chapter,Real user search,Times searched,Likely heading,Full product description,Commodity code (10 digits),Status,Completed by,Notes\n")
    end
  end

  describe "POST #bulk_import" do
    let(:csv_text) do
      <<~CSV
        Chapter,Real user search,Full product description,Commodity code (10 digits),Status
        39,plastic box,A plastic box.,3924100000,Done
      CSV
    end
    let(:upload) { Rack::Test::UploadedFile.new(StringIO.new(csv_text), "text/csv", original_filename: "synthetic-atars.csv") }
    let(:make_request) do
      post bulk_import_tariff_knowledge_synthetic_atars_path, params: { tariff_knowledge_synthetic_atar_import: { file: upload } }
    end

    def backend_accepts_csv(csv)
      stub_api_request("/tariff_knowledge_synthetic_atars/bulk_import", :post)
        .with { |request| Rack::Utils.parse_nested_query(request.body).dig("data", "attributes", "csv") == csv }
        .and_return(
          status: 201,
          headers: json_headers,
          body: { data: { type: "tariff_knowledge_synthetic_atar_bulk_import", attributes: { created: 1, updated: 2, unchanged: 3, skipped: 4, total: 6 } } }.to_json,
        )
    end

    context "with a CSV file the backend accepts" do
      before { backend_accepts_csv(csv_text) }

      it { is_expected.to redirect_to(tariff_knowledge_synthetic_atars_path) }

      it "reports the counts" do
        rendered_page

        expect(session.dig("flash", "flashes", "notice")).to eq("Imported 6 synthetic ATaRs: 1 created, 2 updated, 3 unchanged. 4 rows skipped because they are not finished.")
      end
    end

    context "with a workbook that has several sheets" do
      let(:upload) do
        xlsx_upload([
          xlsx_sheet("Instructions", [["Read this first"]], 1),
          xlsx_sheet("Classifications", [["Chapter", "Real user search", "Full product description", "Commodity code (10 digits)", "Status"], ["39", "plastic box", "A plastic box.", "3924100000", "Done"]], 2),
          xlsx_sheet("Progress", [["Total rows"]], 3),
        ])
      end

      before { backend_accepts_csv(csv_text) }

      it "sends the Classifications sheet to the backend as CSV" do
        expect(rendered_page).to redirect_to(tariff_knowledge_synthetic_atars_path)
      end
    end

    context "when the workbook has no Classifications sheet" do
      let(:upload) { xlsx_upload([xlsx_sheet("Instructions", [["Read this first"]], 1)]) }

      it "shows the problem and does not call the backend" do
        expect(rendered_page).to have_http_status(:unprocessable_content)
        expect(rendered_page.body).to include("The workbook has no sheet called &quot;Classifications&quot;.")
      end
    end

    context "when no file is chosen" do
      let(:make_request) { post bulk_import_tariff_knowledge_synthetic_atars_path }

      it "asks for a file" do
        expect(rendered_page).to have_http_status(:unprocessable_content)
        expect(rendered_page.body).to include("Choose a CSV or XLSX file to upload.")
      end
    end

    context "when the backend rejects the rows" do
      before do
        stub_api_request("/tariff_knowledge_synthetic_atars/bulk_import", :post)
          .and_return(
            status: 422,
            headers: json_headers,
            body: { errors: [{ detail: "Line 3: Commodity code must be exactly 10 digits (check that a leading zero has not been dropped)" }, { detail: "Line 9: Real user search appears more than once in the file (first on line 4)" }] }.to_json,
          )
      end

      it "lists every problem and says that nothing was imported" do
        page = Capybara.string(rendered_page.body)

        expect(rendered_page).to have_http_status(:unprocessable_content)
        expect(page).to have_css(".govuk-error-summary", text: "Nothing was imported")
        expect(page).to have_css(".govuk-error-summary li", text: "Line 3: Commodity code must be exactly 10 digits")
        expect(page).to have_css(".govuk-error-summary li", text: "Line 9: Real user search appears more than once")
      end
    end

    context "when the backend cannot be reached" do
      before do
        stub_api_request("/tariff_knowledge_synthetic_atars/bulk_import", :post).to_raise(Faraday::ConnectionFailed)
      end

      it "shows a clear message instead of a generic error page" do
        page = Capybara.string(rendered_page.body)

        expect(rendered_page).to have_http_status(:unprocessable_content)
        expect(page).to have_css(".govuk-error-summary", text: "The import could not be completed. Check the list before you try again. Uploading the same file again is safe.")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :hmrc_admin) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "GET #new" do
    let(:make_request) { get new_tariff_knowledge_synthetic_atar_path }

    it { is_expected.to have_http_status :success }

    it "shows the form" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h1", text: "New synthetic ATaR")
      expect(page).to have_field("Real user search")
      expect(page).to have_field("Chapter")
      expect(page).to have_field("Full product description")
      expect(page).to have_field("Commodity code")
      expect(page).to have_button("Create synthetic ATaR")
    end
  end

  describe "POST #create" do
    let(:make_request) do
      post tariff_knowledge_synthetic_atars_path, params: {
        tariff_knowledge_synthetic_atar: {
          real_user_search: "plastic box",
          chapter: "39",
          times_searched: "25",
          description: "Reusable plastic food storage box with a clip-on lid.",
          goods_nomenclature_item_id: "3924100000",
        },
      }
    end

    context "when the backend accepts it" do
      before do
        stub_api_request("/tariff_knowledge_synthetic_atars", :post)
          .with { |request|
            attributes = Rack::Utils.parse_nested_query(request.body).dig("data", "attributes")
            attributes["real_user_search"] == "plastic box" && attributes["goods_nomenclature_item_id"] == "3924100000"
          }
          .and_return(jsonapi_response("tariff_knowledge_synthetic_atar", synthetic_atar_attributes.merge("resource_id" => synthetic_atar_id)).merge(status: 201))
      end

      it { is_expected.to redirect_to(tariff_knowledge_synthetic_atar_path(synthetic_atar_id)) }

      it "confirms the creation" do
        rendered_page
        expect(session.dig("flash", "flashes", "notice")).to eq("Synthetic ATaR created successfully.")
      end
    end

    context "when the backend rejects it" do
      before do
        stub_api_request("/tariff_knowledge_synthetic_atars", :post)
          .and_return(api_error_response(real_user_search: "is already used by another synthetic ATaR"))
      end

      it { is_expected.to have_http_status :unprocessable_content }

      it "shows the error in the summary and on the field" do
        page = Capybara.string(rendered_page.body)

        expect(page).to have_css(".govuk-error-summary", text: "is already used by another synthetic ATaR")
        expect(page).to have_css(".govuk-error-message", text: "is already used by another synthetic ATaR")
        expect(page).to have_field("Real user search", with: "plastic box")
      end
    end
  end

  describe "GET #show" do
    let(:make_request) { get tariff_knowledge_synthetic_atar_path(synthetic_atar_id) }

    before do
      stub_api_request("/tariff_knowledge_synthetic_atars/#{synthetic_atar_id}").and_return(synthetic_atar_response)
      stub_versions
    end

    it { is_expected.to have_http_status :success }

    it "shows the details, the actions and the version history" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h1", text: "plastic box")
      expect(page).to have_text("3924100000")
      expect(page).to have_text("Reusable plastic food storage box")
      expect(page).to have_link("Edit", href: edit_tariff_knowledge_synthetic_atar_path(synthetic_atar_id))
      expect(page).to have_link("Delete synthetic ATaR", href: delete_tariff_knowledge_synthetic_atar_path(synthetic_atar_id))
      expect(page).to have_text("Version history (2)")
      expect(page).to have_text("Initial version")
      expect(page).to have_text("Changed: Notes")
    end

    context "when the synthetic ATaR does not exist" do
      before do
        stub_api_request("/tariff_knowledge_synthetic_atars/#{synthetic_atar_id}").and_return(status: 404, headers: json_headers, body: { error: "not found" }.to_json)
      end

      it { is_expected.to redirect_to(tariff_knowledge_synthetic_atars_path) }

      it "explains why" do
        rendered_page
        expect(session.dig("flash", "flashes", "alert")).to eq("Synthetic ATaR not found.")
      end
    end

    context "when the user is not a technical operator" do
      let(:current_user) { create(:user, :auditor) }

      it { is_expected.to have_http_status :forbidden }
    end
  end

  describe "GET #edit" do
    let(:make_request) { get edit_tariff_knowledge_synthetic_atar_path(synthetic_atar_id) }

    before do
      stub_api_request("/tariff_knowledge_synthetic_atars/#{synthetic_atar_id}").and_return(synthetic_atar_response)
    end

    it { is_expected.to have_http_status :success }

    it "shows the form filled in" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_field("Real user search", with: "plastic box")
      expect(page).to have_field("Commodity code", with: "3924100000")
      expect(page).to have_button("Save changes")
    end
  end

  describe "PATCH #update" do
    let(:make_request) do
      patch tariff_knowledge_synthetic_atar_path(synthetic_atar_id), params: {
        tariff_knowledge_synthetic_atar: { goods_nomenclature_item_id: "3923100000", notes: "" },
      }
    end

    before do
      stub_api_request("/tariff_knowledge_synthetic_atars/#{synthetic_atar_id}").and_return(synthetic_atar_response)
    end

    context "when the backend accepts it" do
      before do
        stub_api_request("/tariff_knowledge_synthetic_atars/#{synthetic_atar_id}", :patch)
          .with { |request| Rack::Utils.parse_nested_query(request.body).dig("data", "attributes", "goods_nomenclature_item_id") == "3923100000" }
          .and_return(synthetic_atar_response)
      end

      it { is_expected.to redirect_to(tariff_knowledge_synthetic_atar_path(synthetic_atar_id)) }
    end

    context "when the backend rejects it" do
      before do
        stub_api_request("/tariff_knowledge_synthetic_atars/#{synthetic_atar_id}", :patch)
          .and_return(api_error_response(goods_nomenclature_item_id: "must be exactly 10 digits (check that a leading zero has not been dropped)"))
        stub_versions
      end

      it { is_expected.to have_http_status :unprocessable_content }

      it "shows the error" do
        expect(rendered_page.body).to include("must be exactly 10 digits")
      end
    end
  end

  describe "GET #confirm_destroy" do
    let(:make_request) { get delete_tariff_knowledge_synthetic_atar_path(synthetic_atar_id) }

    before do
      stub_api_request("/tariff_knowledge_synthetic_atars/#{synthetic_atar_id}").and_return(synthetic_atar_response)
    end

    it "asks for confirmation" do
      page = Capybara.string(rendered_page.body)

      expect(page).to have_css("h1", text: "Are you sure you want to delete this synthetic ATaR?")
      expect(page).to have_text("plastic box")
      expect(page).to have_button("Delete synthetic ATaR")
    end
  end

  describe "DELETE #destroy" do
    let(:make_request) { delete tariff_knowledge_synthetic_atar_path(synthetic_atar_id) }

    before do
      stub_api_request("/tariff_knowledge_synthetic_atars/#{synthetic_atar_id}").and_return(synthetic_atar_response)
      stub_api_request("/tariff_knowledge_synthetic_atars/#{synthetic_atar_id}", :delete).and_return(status: 204, headers: json_headers, body: nil)
    end

    it { is_expected.to redirect_to(tariff_knowledge_synthetic_atars_path) }

    it "confirms the deletion" do
      rendered_page
      expect(session.dig("flash", "flashes", "notice")).to eq("Synthetic ATaR deleted successfully.")
    end
  end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations, RSpec/MultipleMemoizedHelpers
