module QuotasHelper
  def format_quota_dates(quota)
    dates = []

    dates << "from #{quota.validity_start_date&.to_date&.to_formatted_s(:govuk)}" if quota.validity_start_date
    dates << "to #{quota.validity_end_date&.to_date&.to_formatted_s(:govuk)}" if quota.validity_end_date

    safe_join dates, ' '
  end
end
