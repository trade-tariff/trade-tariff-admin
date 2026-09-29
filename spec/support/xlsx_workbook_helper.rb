require "zip"

# Builds small XLSX workbooks in memory for specs.
#
#   sheets = [
#     xlsx_sheet("Instructions", [["Read this first"]], 1),
#     xlsx_sheet("Classifications", [%w[Chapter Status], %w[39 Done]], 2),
#   ]
#   upload = xlsx_upload(sheets)
#
# A sheet's file name and relationship target are normally worksheets/sheet<number>.xml.
# A spec can pass its own file and target to show that a sheet is found through the
# workbook's relationships file and not by its position.
module XlsxWorkbookHelper
  XLSX_CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".freeze

  def xlsx_sheet(name, rows, number, file: "sheet#{number}.xml", target: "worksheets/#{file}")
    { name:, rows:, file:, target: }
  end

  def xlsx_upload(sheets, filename: "data.xlsx")
    Rack::Test::UploadedFile.new(StringIO.new(xlsx_workbook_content(sheets)), XLSX_CONTENT_TYPE, original_filename: filename)
  end

  def xlsx_workbook_content(sheets)
    buffer = Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry("xl/workbook.xml")
      zip.write <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <sheets>
            #{sheets.each_with_index.map { |sheet, index| %(<sheet name="#{sheet[:name]}" sheetId="#{index + 1}" r:id="rId#{index + 1}"/>) }.join}
          </sheets>
        </workbook>
      XML

      zip.put_next_entry("xl/_rels/workbook.xml.rels")
      zip.write <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          #{sheets.each_with_index.map { |sheet, index| %(<Relationship Id="rId#{index + 1}" Type="worksheet" Target="#{sheet[:target]}"/>) }.join}
        </Relationships>
      XML

      sheets.each do |sheet|
        zip.put_next_entry("xl/worksheets/#{sheet[:file]}")
        zip.write xlsx_worksheet_xml(sheet[:rows])
      end
    end
    buffer.string
  end

  def xlsx_worksheet_xml(rows)
    sheet_rows = rows.each_with_index.map do |values, row_index|
      cells = values.each_with_index.map do |value, column_index|
        reference = "#{('A'.ord + column_index).chr}#{row_index + 1}"
        if value.is_a?(Numeric)
          %(<c r="#{reference}"><v>#{value}</v></c>)
        else
          %(<c r="#{reference}" t="inlineStr"><is><t>#{ERB::Util.html_escape(value)}</t></is></c>)
        end
      end
      %(<row r="#{row_index + 1}">#{cells.join}</row>)
    end

    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <sheetData>#{sheet_rows.join}</sheetData>
      </worksheet>
    XML
  end
end
