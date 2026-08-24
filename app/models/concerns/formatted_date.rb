module FormattedDate
  extend ActiveSupport::Concern

  def normalise_date(date)
    date.is_a?(Date) ? date.to_s : date
  end

  def initialise_date!(date, use_today: false)
    if date.is_a?(Date)
      date
    elsif date
      Date.parse(date)
    else
      use_today ? Time.zone.today : nil
    end
  rescue StandardError
    # reset the input fields to nil
    Rails.logger.debug("Received invalid date: #{date}")
    nil
  end
end
