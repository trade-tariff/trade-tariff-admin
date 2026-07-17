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
    frontend: "#00703c",
    backend_only: "#d4351c",
    unknown: "#505a5f",
    ai_input: "#144e81",
    ai_output: "#00703c",
    ai_embedding: "#912b88",
  }.freeze
  REQUEST_SOURCE_ORDER = %w[frontend backend_only unknown].freeze

  def search_analytics_number(value)
    number_with_delimiter(value.to_i)
  end

  def search_analytics_percentage(value)
    number_to_percentage(value.to_f * 100, precision: 1, strip_insignificant_zeros: true)
  end

  def search_analytics_latency(value)
    "#{number_with_precision(value.to_f / 1_000, precision: 1, strip_insignificant_zeros: true)}s"
  end

  def search_analytics_cost(value)
    number_to_currency(value.to_f, unit: "US$", precision: 6, strip_insignificant_zeros: true)
  end

  def search_analytics_cost_chart_payload(rows)
    search_analytics_decimal_chart_payload(
      rows,
      series: {
        input_cost_usd: "Model input",
        output_cost_usd: "Model output",
        embedding_cost_usd: "Embeddings",
      },
    )
  end

  def search_analytics_ai_operation_rows(operations, total_cost:)
    Array(operations).map do |operation|
      row = operation.with_indifferent_access
      cost = row[:total_cost_usd].to_f

      {
        label: search_analytics_ai_operation_label(row[:event_kind]),
        calls: row[:calls].to_i,
        input_tokens: row[:input_tokens].to_i,
        cached_input_tokens: row[:cached_input_tokens].to_i,
        output_tokens: row[:output_tokens].to_i,
        total_tokens: row[:total_tokens].to_i,
        input_cost_usd: row[:input_cost_usd].to_f,
        output_cost_usd: row[:output_cost_usd].to_f,
        embedding_cost_usd: row[:embedding_cost_usd].to_f,
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

  def search_analytics_request_source_rows(request_sources)
    rows = (request_sources || {}).with_indifferent_access
    ordered_sources = REQUEST_SOURCE_ORDER.select { |source| rows.key?(source) } + (rows.keys.map(&:to_s) - REQUEST_SOURCE_ORDER).sort

    ordered_sources.map do |source|
      row = rows.fetch(source).with_indifferent_access

      {
        key: source.to_s,
        label: search_analytics_request_source_label(source),
        searches: row[:searches].to_i,
        failure_rate: row[:failure_rate].to_f,
        zero_result_rate: row[:zero_result_rate].to_f,
        selection_rate: row[:selection_rate].to_f,
        p90_latency_ms: row[:p90_latency_ms].to_i,
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

  def search_analytics_decimal_chart_payload(rows, series:)
    {
      labels: Array(rows).map { |row| search_analytics_bucket_label(row[:bucket] || row["bucket"]) },
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

  def search_analytics_request_source_label(source)
    {
      "frontend" => "Frontend-routed",
      "backend_only" => "Direct backend / non-frontend",
      "unknown" => "Unknown",
    }.fetch(source.to_s, source.to_s.humanize)
  end

  def search_analytics_ai_operation_label(event_kind)
    {
      "interactive_search" => "Interactive search",
      "interactive_search_final_answer" => "Final answer",
      "search_query_expansion" => "Query expansion",
      "duplicate_question_guard" => "Duplicate-question guard",
      "vector_search_query_embedding" => "Vector query embedding",
    }.fetch(event_kind.to_s, event_kind.to_s.humanize)
  end
end
