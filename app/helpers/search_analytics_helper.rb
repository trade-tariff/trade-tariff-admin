module SearchAnalyticsHelper
  SEARCH_ANALYTICS_CHART_COLOURS = {
    all: "#144e81",
    classic: "#005a30",
    internal: "#594d00",
    completed: "#144e81",
    failed: "#942514",
    zero_result: "#594d00",
    selected: "#005a30",
    searches: "#144e81",
    ai_total: "#144e81",
  }.freeze
  def search_analytics_number(value)
    number_with_delimiter(value.to_i)
  end

  def search_analytics_percentage(value)
    number_to_percentage(value.to_f * 100, precision: 1, strip_insignificant_zeros: true)
  end

  def search_analytics_share(value)
    return "<0.1%" if value.to_f.positive? && value.to_f < 0.001

    search_analytics_percentage(value)
  end

  def search_analytics_latency(value)
    return "Unavailable" if value.nil?

    if value.to_f < 1_000
      "#{number_with_precision(value, precision: 1, strip_insignificant_zeros: true)}ms"
    else
      "#{number_with_precision(value.to_f / 1_000, precision: 3, strip_insignificant_zeros: true)}s"
    end
  end

  def search_analytics_cost(value)
    return "Unavailable" if value.nil?

    amount = value.to_d
    return "<$0.01" if amount.positive? && amount < 0.01

    number_to_currency(amount, unit: "$", precision: 2)
  end

  def search_analytics_cost_chart_payload(rows, bucket_size: "day")
    search_analytics_decimal_chart_payload(
      rows,
      bucket_size:,
      series: { total_cost_usd: "Estimated AI cost" },
    )
  end

  def search_analytics_ai_operation_rows(operations, total_cost:)
    Array(operations).map do |operation|
      row = operation.with_indifferent_access
      cost = row[:total_cost_usd].to_f

      {
        label: search_analytics_ai_operation_label(row[:event_kind]),
        calls: row[:calls].to_i,
        total_cost_usd: cost,
        share: total_cost.to_f.positive? ? cost / total_cost.to_f : 0,
      }
    end
  end

  def search_analytics_status_tag_colour(level)
    {
      "good" => "green",
      "watch" => "yellow",
      "problem" => "red",
      "neutral" => "blue",
    }.fetch(level.to_s, "grey")
  end

  def search_analytics_chart_payload(rows, series:, minimum_series_share: 0, bucket_size: "day")
    series_data = series.keys.index_with do |key|
      Array(rows).map { |row| (row[key] || row[key.to_s]).to_i }
    end
    largest_series_total = series_data.values.map(&:sum).max.to_i

    {
      labels: Array(rows).map { |row| search_analytics_bucket_label(row[:bucket] || row["bucket"], bucket_size:) },
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

  def search_analytics_date(value)
    return if value.blank?

    Time.zone.parse(value.to_s).utc.to_date.to_fs(:govuk)
  rescue ArgumentError
    value.to_s
  end

  def search_analytics_bucket_date(value, bucket_size:)
    date = search_analytics_date(value)
    bucket_size == "hour" ? "#{date}, #{search_analytics_bucket_label(value, bucket_size:)}" : date
  end

private

  def search_analytics_decimal_chart_payload(rows, series:, bucket_size:)
    {
      labels: Array(rows).map { |row| search_analytics_bucket_label(row[:bucket] || row["bucket"], bucket_size:) },
      datasets: series.filter_map do |key, label|
        data = Array(rows).map { |row| (row[key] || row[key.to_s]).to_f }
        next if data.all?(&:zero?)

        {
          label: label,
          data: data,
        }.merge(search_analytics_chart_series_style("ai_#{key.to_s.delete_suffix('_cost_usd')}"))
      end,
    }.to_json
  end

  def search_analytics_bucket_label(value, bucket_size:)
    return search_analytics_date(value) unless bucket_size == "hour"

    time = Time.zone.parse(value.to_s).utc
    "#{search_analytics_time_label(time)} to #{search_analytics_time_label(time + 1.hour)}"
  rescue ArgumentError
    value.to_s
  end

  def search_analytics_time_label(time)
    return "midnight" if time.hour.zero? && time.min.zero?
    return "midday" if time.hour == 12 && time.min.zero?

    time.strftime(time.min.zero? ? "%-I%P" : "%-I:%M%P")
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

  def search_analytics_ai_operation_label(event_kind)
    {
      "interactive_search" => "AI-assisted search",
      "interactive_search_final_answer" => "AI answer",
      "search_query_expansion" => "Search term expansion",
      "duplicate_question_guard" => "Duplicate question check",
      "vector_search_query_embedding" => "Search matching preparation",
    }.fetch(event_kind.to_s, event_kind.to_s.humanize)
  end
end
