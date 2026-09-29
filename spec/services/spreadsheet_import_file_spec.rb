# rubocop:disable RSpec/MultipleExpectations
# The single-sheet behaviour is covered by description_intercept_import_file_spec.rb.
# This spec covers picking a sheet by name in a workbook with several sheets.
RSpec.describe SpreadsheetImportFile do
  include XlsxWorkbookHelper

  let(:instructions) { xlsx_sheet("Instructions", [["Read this first"]], 1) }
  let(:classifications) { xlsx_sheet("Classifications", [%w[Chapter Status], %w[39 Done]], 2) }
  let(:progress) { xlsx_sheet("Progress", [["Total rows"]], 3) }

  def upload(content, filename:, content_type:)
    Rack::Test::UploadedFile.new(StringIO.new(content), content_type, original_filename: filename)
  end

  describe "#call with a sheet name" do
    def call(sheets, sheet_name: "Classifications")
      described_class.new(xlsx_upload(sheets), sheet_name:).call
    end

    it "reads the named sheet even when it is not the first one" do
      result = call([instructions, classifications, progress])

      expect(result).to be_success
      expect(result.csv_content).to eq("Chapter,Status\n39,Done\n")
    end

    it "finds the sheet through the relationships file, not by its position" do
      moved = xlsx_sheet("Classifications", classifications[:rows], 1, file: "sheet9.xml")

      expect(call([moved, instructions]).csv_content).to eq("Chapter,Status\n39,Done\n")
    end

    it "accepts a relationship target that starts with a slash" do
      absolute = xlsx_sheet("Classifications", classifications[:rows], 2, target: "/xl/worksheets/sheet2.xml")

      expect(call([instructions, absolute]).csv_content).to eq("Chapter,Status\n39,Done\n")
    end

    it "ignores case in the sheet name" do
      expect(call([instructions, classifications], sheet_name: "classifications")).to be_success
    end

    it "keeps numeric cells" do
      numeric = xlsx_sheet("Classifications", [["Times searched"], [25]], 2)

      expect(call([instructions, numeric]).csv_content).to eq("Times searched\n25\n")
    end

    it "quotes cells that contain commas or new lines" do
      tricky = xlsx_sheet("Classifications", [["Description"], ["Box, plastic\nwith lid"]], 2)

      expect(call([instructions, tricky]).csv_content).to eq(%(Description\n"Box, plastic\nwith lid"\n))
    end

    it "reports a workbook that has no sheet with that name" do
      result = call([instructions, progress])

      expect(result).not_to be_success
      expect(result.errors).to eq([{ "detail" => %(The workbook has no sheet called "Classifications".) }])
    end
  end

  describe "#call without a sheet name" do
    it "still refuses a workbook with more than one sheet" do
      result = described_class.new(xlsx_upload([instructions, classifications])).call

      expect(result.errors).to eq([{ "detail" => "Upload an XLSX file with a single worksheet." }])
    end
  end

  describe "#call with other files" do
    it "returns CSV text unchanged" do
      upload = upload("Chapter,Status\n39,Done\n", filename: "data.csv", content_type: "text/csv")

      result = described_class.new(upload, sheet_name: "Classifications").call

      expect(result).to be_success
      expect(result.csv_content).to eq("Chapter,Status\n39,Done\n")
    end

    it "asks for a file when there is none" do
      expect(described_class.new(nil).call.errors).to eq([{ "detail" => "Choose a CSV or XLSX file to upload." }])
    end

    it "rejects other file types" do
      upload = upload("hello", filename: "data.txt", content_type: "text/plain")

      expect(described_class.new(upload).call.errors).to eq([{ "detail" => "Upload a CSV or XLSX file." }])
    end

    it "rejects an XLSX file that is not a valid archive" do
      upload = upload("this is not a zip file", filename: "data.xlsx", content_type: XlsxWorkbookHelper::XLSX_CONTENT_TYPE)

      expect(described_class.new(upload, sheet_name: "Classifications").call.errors).to eq([{ "detail" => "Upload a valid CSV or XLSX file." }])
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
