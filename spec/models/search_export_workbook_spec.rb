RSpec.describe SearchExportWorkbook do
  describe ".create" do
    before do
      stub_api_request("/search_export/workbooks", :post)
        .with(body: { from: "2026-09-23", to: "2026-09-24" }.to_json,
              headers: { "Content-Type" => "application/json" })
        .to_return jsonapi_response(:search_export_workbook, { resource_id: "42", status: "queued" }, status: 202)
    end

    it "posts the date range and parses the queued resource" do
      expect(described_class.create(from: "2026-09-23", to: "2026-09-24"))
        .to have_attributes(resource_id: "42", status: "queued")
    end
  end

  describe ".find" do
    before do
      stub_api_request("/search_export/workbooks/42")
        .to_return jsonapi_response(:search_export_workbook, { resource_id: "42", status: "ready", row_count: 5, omitted_count: 2 })
    end

    it "parses the stored export status and counts" do
      expect(described_class.find("42")).to have_attributes(status: "ready", row_count: 5, omitted_count: 2)
    end
  end

  describe ".download" do
    let(:bytes) { "PK\x03\x04\xFF\x00".b }

    before do
      stub_api_request("/search_export/workbooks/42/download").to_return(
        status: 200, body: bytes,
        headers: { "Content-Type" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }
      )
    end

    it "keeps binary workbook bytes unchanged" do
      expect(described_class.download("42").body.b).to eq(bytes)
    end
  end
end
