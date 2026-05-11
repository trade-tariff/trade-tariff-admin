require "csv"
require "zip"

class DescriptionInterceptImportFile
  Result = Data.define(:csv_content, :errors) do
    def success?
      errors.blank?
    end
  end

  def initialize(upload)
    @upload = upload
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

  attr_reader :upload

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
      return failure("Upload an XLSX file with a single worksheet.") unless workbook.css("sheet").one?

      shared_strings = shared_strings(zip)
      sheet = xml(zip, "xl/worksheets/sheet1.xml")
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
