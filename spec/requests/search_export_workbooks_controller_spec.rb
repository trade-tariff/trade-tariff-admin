RSpec.describe SearchExportWorkbooksController, :aggregate_failures do
  include_context "with authenticated user"

  let(:export) do
    SearchExportWorkbook.new(resource_id: "42", status: "queued", from: "2026-09-23", to: "2026-09-24")
  end

  before do
    allow(SearchExportWorkbook).to receive(:create).and_return(export)
    allow(SearchExportWorkbook).to receive(:find).with("42").and_return(export)
  end

  it "stops automatic polling after three minutes" do
    get search_export_workbook_path("42", poll: 90)

    expect(response.headers["Refresh"]).to be_nil
    expect(response.body).to include("Automatic checks have stopped", "Check workbook status")
  end

  it "shows a helpful state for a missing workbook" do
    allow(SearchExportWorkbook).to receive(:find).with("42").and_raise(Faraday::ResourceNotFound)

    get search_export_workbook_path("42")

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("Workbook not found")
  end

  it "shows a helpful state for a missing download" do
    allow(SearchExportWorkbook).to receive(:download).and_raise(Faraday::ResourceNotFound)

    get download_search_export_workbook_path("42")

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("Workbook not found")
  end

  it "handles a backend outage during creation" do
    allow(SearchExportWorkbook).to receive(:create).and_raise(Faraday::ConnectionFailed)

    post search_export_workbooks_path, params: { from: "2026-09-23", to: "2026-09-24" }

    expect(response).to have_http_status(:redirect)
    expect(flash[:alert]).to include("service is unavailable")
  end

  it "handles a backend outage during polling" do
    allow(SearchExportWorkbook).to receive(:find).and_raise(Faraday::ConnectionFailed)

    get search_export_workbook_path("42")

    expect(response).to have_http_status(:service_unavailable)
    expect(response.headers["Refresh"]).to be_nil
  end

  describe "POST /search_export_workbooks" do
    before do
      post search_export_workbooks_path, params: { from: "2026-09-23", to: "2026-09-24" }
    end

    it "queues the selected dates" do
      expect(SearchExportWorkbook).to have_received(:create).with(from: "2026-09-23", to: "2026-09-24")
    end

    it "redirects to progress" do
      expect(response).to redirect_to(search_export_workbook_path("42"))
    end

    context "when the user is a guest" do
      let(:current_user) { create(:user, :guest) }

      it "denies creation" do
        expect(response).to have_http_status(:forbidden)
      end

      it "does not send a backend request" do
        expect(SearchExportWorkbook).not_to have_received(:create)
      end
    end
  end

  describe "GET /search_export_workbooks/:id" do
    before { get search_export_workbook_path("42") }

    it "serves the progress page" do
      expect(response).to have_http_status(:ok)
    end

    it "refreshes while queued" do
      expect(response.headers["Refresh"]).to eq("2; url=#{search_export_workbook_path('42', poll: 1)}")
    end

    it "shows progress" do
      expect(response.body).to include("Building the workbook")
    end

    context "when ready" do
      let(:export) { SearchExportWorkbook.new(resource_id: "42", status: "ready", row_count: 5, omitted_count: 2) }

      it "stops polling" do
        expect(response.headers["Refresh"]).to be_nil
      end

      it "offers the download and reports omissions" do
        expect(response.body).to include(download_search_export_workbook_path("42"), "Omitted journeys: 2")
      end
    end

    context "when failed" do
      let(:export) { SearchExportWorkbook.new(resource_id: "42", status: "failed", error: "Shorten the date range.") }

      it "stops polling" do
        expect(response.headers["Refresh"]).to be_nil
      end

      it "shows the failure" do
        expect(response.body).to include("Shorten the date range.")
      end
    end

    context "when the user is a guest" do
      let(:current_user) { create(:user, :guest) }

      it "denies progress access" do
        expect(response).to have_http_status(:forbidden)
      end

      it "does not fetch the export" do
        expect(SearchExportWorkbook).not_to have_received(:find)
      end
    end
  end

  describe "GET /search_export_workbooks/:id/download" do
    let(:bytes) { "PK\x03\x04\xFF\x00".b }

    before do
      stub_api_request("/search_export/workbooks/42/download").to_return(
        status: 200, body: bytes,
        headers: { "Content-Type" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }
      )
      get download_search_export_workbook_path("42")
    end

    it "serves the backend bytes unchanged" do
      expect(response.body.b).to eq(bytes)
    end

    it "includes the date range in the filename" do
      expect(response.headers["Content-Disposition"]).to include("classifier-workbook-2026-09-23-2026-09-24.xlsx")
    end

    it "serves an Excel workbook" do
      expect(response.media_type).to eq("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    end

    context "when the user is a guest" do
      let(:current_user) { create(:user, :guest) }

      it "denies downloads" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
