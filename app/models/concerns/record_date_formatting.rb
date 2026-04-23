module RecordDateFormatting
  def formatted_created_at
    formatted_record_date(created_at)
  end

  def formatted_updated_at
    formatted_record_date(updated_at)
  end

private

  def formatted_record_date(value)
    return "-" if value.blank?

    date = Date.parse(value.to_s)
    date == Date.current ? "Today" : date.to_formatted_s(:govuk)
  rescue ArgumentError
    value.to_s
  end
end
