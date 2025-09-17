module QuotasHelper
  def formatted_initial_volume(quota_definition)
    volume = number_with_precision quota_definition.initial_volume, precision: 3, delimiter: ","

    "#{volume} #{quota_definition.formatted_measurement_unit}"
  end

  def format_quota_dates(quota_definition)
    dates = []

    dates << "from #{quota_definition.validity_start_date&.to_date&.to_formatted_s(:govuk)}" if quota_definition.validity_start_date
    dates << "to #{quota_definition.validity_end_date&.to_date&.to_formatted_s(:govuk)}" if quota_definition.validity_end_date

    safe_join dates, " "
  end
end
