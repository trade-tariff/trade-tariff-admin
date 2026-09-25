RSpec.describe SearchExportWorkbooksHelper do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.utc(2026, 9, 25), &example) }

  [
    ["2026-09-24", "2026-09-24", "24h", "Last 24 hours"],
    ["2026-09-18", "2026-09-24", "7d", "Last 7 days"],
    ["2026-08-26", "2026-09-24", "30d", "Last 30 days"],
    ["2026-09-24", "2026-09-24", "custom", "For 24 September 2026"],
    ["2026-09-01", "2026-09-24", "7d", "1 September 2026 to 24 September 2026"],
    ["2026-09-01", "2026-09-03", nil, "1 September 2026 to 3 September 2026"],
    ["2026-09-25", "2026-09-25", "unknown", "For 25 September 2026"],
  ].each do |from, to, preset, expected|
    it "labels #{from} to #{to} with preset #{preset.inspect}" do
      export = SearchExportWorkbook.new(from:, to:)
      expect(helper.workbook_date_label(export, preset)).to eq(expected)
    end
  end
end
