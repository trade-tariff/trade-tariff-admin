module SearchAnalyticsHelper
  VIEW_SUMMARY_MINIMUM_INTERNAL_SHARE = 1.0

  SEARCH_ANALYTICS_CHART_COLOURS = {
    all: "#144e81",
    classic: "#005a30",
    internal: "#594d00",
    completed: "#144e81",
    failed: "#942514",
    zero_result: "#594d00",
    selected: "#005a30",
    searches: "#144e81",
  }.freeze

  def search_analytics_number(value)
    number_with_delimiter(value.to_i)
  end

  def search_analytics_percentage(value)
    number_to_percentage(value.to_f * 100, precision: 1, strip_insignificant_zeros: true)
  end

  def search_analytics_latency(value)
    "#{number_with_precision(value.to_f / 1_000, precision: 1, strip_insignificant_zeros: true)}s"
  end

  def search_analytics_status_tag_colour(level)
    {
      "good" => "green",
      "watch" => "yellow",
      "problem" => "red",
      "neutral" => "blue",
    }.fetch(level.to_s, "grey")
  end

  def search_analytics_chart_payload(rows, series:, minimum_series_share: 0)
    series_data = series.keys.index_with do |key|
      Array(rows).map { |row| (row[key] || row[key.to_s]).to_i }
    end
    largest_series_total = series_data.values.map(&:sum).max.to_i

    {
      labels: Array(rows).map { |row| search_analytics_bucket_label(row[:bucket] || row["bucket"]) },
      datasets: series.filter_map do |key, label|
        data = series_data.fetch(key)
        next if data.all?(&:zero?)
        next if largest_series_total.positive? && ((data.sum.to_f / largest_series_total) * 100) < minimum_series_share

        {
          label: label,
          data: data,
        }.merge(search_analytics_chart_series_style(key))
      end,
    }.to_json
  end

  def search_analytics_view_summary_rows(comparisons)
    rows = (comparisons || {}).with_indifferent_access.slice(:classic, :internal)
    total_searches = rows.values.sum { |row| (row[:searches] || row["searches"]).to_i }

    rows.map do |view, row|
      searches = (row[:searches] || row["searches"]).to_i
      percentage = total_searches.positive? ? ((searches.to_f / total_searches) * 100).round(1) : 0.0

      {
        key: view.to_s,
        label: view.to_s.humanize,
        searches: searches,
        percentage: "#{number_with_precision(percentage, precision: 1, strip_insignificant_zeros: true)}%",
        width: percentage,
      }
    end
  end

  def search_analytics_show_view_summary?(comparisons)
    rows = (comparisons || {}).with_indifferent_access
    total_searches = rows.slice(:classic, :internal).values.sum { |row| (row[:searches] || row["searches"]).to_i }
    internal_searches = (rows.dig(:internal, :searches) || rows.dig(:internal, "searches")).to_i

    return false unless total_searches.positive?

    ((internal_searches.to_f / total_searches) * 100) >= VIEW_SUMMARY_MINIMUM_INTERNAL_SHARE
  end

  def search_analytics_timestamp(value)
    return if value.blank?

    time = Time.zone.parse(value.to_s)
    "#{time.to_date.to_fs(:govuk)} at #{time.strftime('%H:%M')}"
  rescue ArgumentError
    value.to_s
  end

private

  def search_analytics_bucket_label(bucket)
    time = Time.zone.parse(bucket.to_s)
    return time.strftime("%-d %b") if time.hour.zero? && time.min.zero?

    time.strftime("%H:%M")
  rescue ArgumentError
    bucket.to_s
  end

  def search_analytics_chart_series_style(key)
    colour = SEARCH_ANALYTICS_CHART_COLOURS.fetch(key.to_sym, SEARCH_ANALYTICS_CHART_COLOURS.fetch(:all))

    {
      borderColor: colour,
      backgroundColor: colour,
      pointBackgroundColor: colour,
      pointBorderColor: colour,
    }
  end
end
