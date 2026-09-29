require "csv"
require "zip"

# Turns an uploaded CSV or XLSX file into CSV text that the backend can import.
#
# An XLSX file is read from the sheet called `sheet_name`, wherever that sheet is in
# the workbook. Without a sheet name the workbook must contain exactly one sheet,
# which is how the description intercept import works.
class SpreadsheetImportFile
  Result = Data.define(:csv_content, :errors) do
    def success?
      errors.blank?
    end
  end

  def initialize(upload, sheet_name: nil)
    @upload = upload
    @sheet_name = sheet_name
  end

  def call
    return failure("Choose a CSV or XLSX file to upload.") if upload.blank?

    if xlsx?
      xlsx_to_csv
    elsif csv?
      Result.new(csv_content: upload.read, errors: [])
    else
      failure("Upload a CSV or XLSX file.")
    end
  end

private

  attr_reader :upload, :sheet_name

  def csv?
    extension == ".csv" || content_type == "text/csv"
  end

  def xlsx?
    extension == ".xlsx" || content_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  def extension
    File.extname(upload.original_filename.to_s).downcase
  end

  def content_type
    upload.content_type.to_s
  end

  def xlsx_to_csv
    rows = []

    Zip::File.open_buffer(upload.read) do |zip|
      workbook = xml(zip, "xl/workbook.xml")
      sheet_path = worksheet_path(zip, workbook)
      return failure(missing_sheet_message) if sheet_path.blank?

      shared_strings = shared_strings(zip)
      sheet = xml(zip, sheet_path)
      rows = sheet.css("sheetData row").map do |row|
        cells = row.css("c")
        next [] if cells.empty?

        width = cells.map { |cell| column_index(cell["r"]) }.max
        values = Array.new(width)
        cells.each do |cell|
          values[column_index(cell["r"]) - 1] = cell_value(cell, shared_strings)
        end
        values
      end
    end

    Result.new(csv_content: CSV.generate { |csv| rows.each { |row| csv << row } }, errors: [])
  rescue Zip::Error, Nokogiri::XML::SyntaxError
    failure("Upload a valid CSV or XLSX file.")
  end

  # Returns the path of the worksheet inside the XLSX archive, or nil when the
  # requested sheet is not there (or, with no sheet name, when there is more than one).
  def worksheet_path(zip, workbook)
    sheets = workbook.css("sheet")

    if sheet_name.present?
      sheet = sheets.find { |candidate| candidate["name"].to_s.strip.casecmp?(sheet_name) }
      sheet && relationship_target(zip, sheet["id"])
    elsif sheets.one?
      "xl/worksheets/sheet1.xml"
    end
  end

  # The workbook lists each sheet with a relationship id. The relationships file
  # says which worksheet file that id points to. Its target is written relative to
  # the xl folder, or from the root of the archive when it starts with a slash.
  def relationship_target(zip, relationship_id)
    relationships = xml(zip, "xl/_rels/workbook.xml.rels")
    relationship = relationships.css("Relationship").find { |candidate| candidate["Id"] == relationship_id }
    target = relationship && relationship["Target"].to_s.delete_prefix("/")
    return if target.blank?

    target.start_with?("xl/") ? target : "xl/#{target}"
  end

  def missing_sheet_message
    if sheet_name.present?
      %(The workbook has no sheet called "#{sheet_name}".)
    else
      "Upload an XLSX file with a single worksheet."
    end
  end

  def shared_strings(zip)
    entry = zip.find_entry("xl/sharedStrings.xml")
    return [] if entry.blank?

    xml = Nokogiri::XML(entry.get_input_stream.read)
    xml.remove_namespaces!
    xml.css("si").map { |item| item.css("t").map(&:text).join }
  end

  def xml(zip, path)
    entry = zip.find_entry(path)
    raise Zip::Error, "#{path} not found" if entry.blank?

    xml = Nokogiri::XML(entry.get_input_stream.read)
    xml.remove_namespaces!
    xml
  end

  def cell_value(cell, shared_strings)
    value = cell.at_css("v")&.text

    if cell["t"] == "s"
      shared_strings[value.to_i]
    elsif cell["t"] == "inlineStr"
      cell.css("is t").map(&:text).join
    else
      value
    end
  end

  def column_index(reference)
    column = reference.to_s[/[A-Z]+/]
    return 1 if column.blank?

    column.chars.reduce(0) { |sum, char| (sum * 26) + char.ord - 64 }
  end

  def failure(message)
    Result.new(csv_content: nil, errors: [{ "detail" => message }])
  end
end
