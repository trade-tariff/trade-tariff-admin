# rubocop:disable RSpec/MultipleExpectations
require "zip"

RSpec.describe DescriptionInterceptImportFile do
  describe "#call" do
    it "passes CSV uploads through unchanged" do
      upload = Rack::Test::UploadedFile.new(StringIO.new("term,aliases,template\ngift,\"present,gifts\",generic\n"), "text/csv", original_filename: "intercepts.csv")

      result = described_class.new(upload).call

      expect(result).to be_success
      expect(result.csv_content).to eq("term,aliases,template\ngift,\"present,gifts\",generic\n")
    end

    it "converts a single-sheet XLSX upload to CSV" do
      upload = Rack::Test::UploadedFile.new(StringIO.new(xlsx_content), "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", original_filename: "intercepts.xlsx")

      result = described_class.new(upload).call

      expect(result).to be_success
      expect(result.csv_content).to eq("term,aliases,template\ngift,\"present,gifts\",generic\n")
    end

    it "rejects unsupported file types" do
      upload = Rack::Test::UploadedFile.new(StringIO.new("hello"), "text/plain", original_filename: "intercepts.txt")

      result = described_class.new(upload).call

      expect(result).not_to be_success
      expect(result.errors).to eq([{ "detail" => "Upload a CSV or XLSX file." }])
    end

    it "rejects XLSX files with more than one worksheet" do
      upload = Rack::Test::UploadedFile.new(StringIO.new(xlsx_content(sheet_count: 2)), "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", original_filename: "intercepts.xlsx")

      result = described_class.new(upload).call

      expect(result).not_to be_success
      expect(result.errors).to eq([{ "detail" => "Upload an XLSX file with a single worksheet." }])
    end
  end

  def xlsx_content(sheet_count: 1)
    buffer = Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry("xl/workbook.xml")
      zip.write <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <sheets>
            #{Array.new(sheet_count) { |index| %(<sheet name="Sheet#{index + 1}" sheetId="#{index + 1}" r:id="rId#{index + 1}"/>) }.join}
          </sheets>
        </workbook>
      XML

      zip.put_next_entry("xl/sharedStrings.xml")
      zip.write <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <si><t>term</t></si>
          <si><t>aliases</t></si>
          <si><t>template</t></si>
          <si><t>gift</t></si>
          <si><t>present,gifts</t></si>
          <si><t>generic</t></si>
        </sst>
      XML

      zip.put_next_entry("xl/worksheets/sheet1.xml")
      zip.write <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <sheetData>
            <row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c><c r="C1" t="s"><v>2</v></c></row>
            <row r="2"><c r="A2" t="s"><v>3</v></c><c r="B2" t="s"><v>4</v></c><c r="C2" t="s"><v>5</v></c></row>
          </sheetData>
        </worksheet>
      XML
    end

    buffer.string
  end
end

# rubocop:enable RSpec/MultipleExpectations
