module SearchAnalyticsHelper
  SEARCH_ANALYTICS_CHART_COLOURS = {
    all: "#144e81",
    classic: "#005a30",
    internal: "#594d00",
    completed: "#144e81",
    failed: "#942514",
    nonterminal: "#f47738",
    unknown: "#505a5f",
    zero_result: "#594d00",
    selected: "#005a30",
    searches: "#144e81",
    navigation: "#144e81",
    search: "#005a30",
    unclassified: "#505a5f",
    ai_total: "#144e81",
  }.freeze
  def search_analytics_frontend_selection_rows(selections)
    Array(selections).map do |selection|
      row = selection.with_indifferent_access
      rank = row[:result_rank]
      confidence = row[:confidence].presence&.humanize || "Unknown"
      label = rank.nil? ? "Unknown rank, #{confidence}" : "Rank #{rank}, #{confidence}"
      [label, row[:event_count].to_i]
    end
  end

  def search_analytics_ai_model_rows(models, total_cost:)
    Array(models).map do |model|
      row = model.with_indifferent_access
      cost = row[:total_cost_usd].to_f
      {
        label: search_analytics_unknown_model_label(row[:model]),
        calls: row[:calls].to_i,
        total_cost_usd: cost,
        share: total_cost.to_f.positive? ? cost / total_cost.to_f : 0,
      }
    end
  end

  def search_analytics_unknown_model_label(model)
    name = model.to_s
    name.blank? || name == "unknown" ? "Unknown" : name
  end

  GUIDED_OUTCOME_RATE_LABELS = {
    "results" => "Results",
    "dont_know" => "I don't know",
    "no_results" => "No results",
    "unknown_results" => "Unknown results",
    "blocking_guidance" => "Blocking guidance",
    "error" => "Error",
    "abandonment" => "Abandonment",
  }.freeze
  CLASSIC_OUTCOME_RATE_LABELS = {
    "results" => "Results",
    "no_results" => "No results",
  }.freeze
  QUESTION_OUTCOME_RATE_LABELS = {
    "server_accepted" => "Answered",
    "dont_know" => "I don't know",
    "unanswered" => "Abandonment",
  }.freeze

  OUTCOME_RATE_COLOURS = {
    "results" => "#005a30",
    "server_accepted" => "#005a30",
    "dont_know" => "#f47738",
    "no_results" => "#594d00",
    "unknown_results" => "#505a5f",
    "blocking_guidance" => "#144e81",
    "error" => "#942514",
    "abandonment" => "#6f777b",
    "unanswered" => "#6f777b",
  }.freeze

  def search_analytics_outcome_rate_rows(population, labels)
    population = (population || {}).with_indifferent_access
    counts = population[:counts]&.with_indifferent_access
    percentages = population[:percentages]&.with_indifferent_access
    labels.map do |key, label|
      {
        key: key,
        label: label,
        count: counts ? counts[key].to_i : nil,
        percentage: percentages ? percentages[key] : nil,
      }
    end
  end

  def search_analytics_outcome_rate_axis_label(label)
    words = label.to_s.split
    return label if words.length < 2

    midpoint = (words.length / 2.0).ceil
    [words.first(midpoint).join(" "), words.drop(midpoint).join(" ")]
  end

  def search_analytics_outcome_rate_chart_payload(rows)
    colours = rows.map { |row| OUTCOME_RATE_COLOURS.fetch(row[:key], "#144e81") }
    {
      labels: rows.map { |row| search_analytics_outcome_rate_axis_label(row[:label]) },
      datasets: [{
        label: "Rate",
        data: rows.map { |row| row[:percentage].nil? ? nil : row[:percentage].to_f },
        backgroundColor: colours,
        borderColor: colours,
        maxBarThickness: 72,
      }],
    }.to_json
  end

  def search_analytics_outcome_rate_percentage(value)
    return "Unavailable" if value.nil?

    number_to_percentage(value.to_f, precision: 1, strip_insignificant_zeros: true)
  end

  def search_analytics_outcome_definition(view)
    case view
    when "internal"
      "Each started journey counts once. If it reaches more than one terminating outcome on the same UTC day, the last recorded outcome is used. Rates use journeys started as the denominator. Abandonment is a started journey with no terminating outcome that day. A journey that ends on a later day can count as abandoned on the start day. Missing collection is not abandonment. When no journeys start, rates are unavailable."
    when "classic"
      "Results and No results are shares of completed frontend fuzzy searches. Exact matches are excluded. No results means the total result count is 0. These figures do not prove that a results page was visible. There is no classic abandonment rate. When no fuzzy searches complete, rates are unavailable."
    else
      "Uses the same frontend journeys as Total journeys. Completed means a final backend response, not a question step. Question only and Unknown show journeys without a recognised final outcome. Selected and Zero result can overlap with other states. Outcomes are shown in the journey's observed start buckets."
    end
  end

  def search_analytics_frontend_action_rows(actions)
    actions = (actions || {}).with_indifferent_access
    [["Result selections", actions[:result_selected].to_i], ["Don't know", actions[:dont_know].to_i]]
  end

  def search_analytics_frontend_chart_payload(rows, label:, pie: false)
    {
      labels: rows.map(&:first),
      datasets: [{
        label:,
        data: rows.map(&:last),
        backgroundColor: pie ? ["#144e81", "#f47738"] : "#144e81",
        maxBarThickness: 72,
      }.merge(pie ? {} : { borderColor: "#144e81", pointBackgroundColor: "#144e81", pointBorderColor: "#144e81" })],
    }.to_json
  end

  def search_analytics_frontend_question_rows(rows)
    Array(rows).group_by { |row| search_analytics_question_bucket(row.with_indifferent_access[:questions]) }.map do |label, group|
      [label, group.sum { |row| row.with_indifferent_access[:journeys].to_i }]
    end
  end

  def search_analytics_question_bucket(value)
    return "Unknown" if value.nil?

    value.to_i >= 8 ? "8+" : value.to_i.to_s
  end

  def search_analytics_query_collected?(coverage, name)
    queries = coverage.with_indifferent_access[:queries]
    return true if queries.blank?

    queries.dig(name, :collected_days).to_i.positive?
  end

  SEARCH_ACTION_LABELS = { navigation: "Navigation", search: "Search", unclassified: "Unclassified" }.freeze

  def search_analytics_actions(analytics)
    return analytics.actions.with_indifferent_access if analytics.actions.present?

    available = analytics.availability&.dig(:journey_metrics)
    total = analytics.summary&.dig(:searches) if available
    {
      available: false,
      summary: { total:, navigation: nil, search: nil, unclassified: total },
      trend: if available
               Array(analytics.trends&.dig(:volume)).map do |row|
                 row = row.with_indifferent_access
                 { bucket: row[:bucket], total: row[analytics.view], navigation: nil, search: nil, unclassified: row[analytics.view] }
               end
             else
               []
             end,
    }.with_indifferent_access
  end

  def search_analytics_action_count(value)
    value.nil? ? "Unavailable" : search_analytics_number(value)
  end

  def search_analytics_action_chart_payload(rows, bucket_size:)
    rows = Array(rows).map(&:with_indifferent_access)
    {
      labels: rows.map { |row| search_analytics_bucket_label(row[:bucket], bucket_size:) },
      datasets: SEARCH_ACTION_LABELS.filter_map do |key, label|
        data = rows.map { |row| row[key] }
        next if data.all?(&:nil?)

        { label:, data: }.merge(search_analytics_chart_series_style(key))
      end,
    }.to_json
  end

  def search_analytics_number(value)
    number_with_delimiter(value.to_i)
  end

  def search_analytics_percentage(value)
    return "Unavailable" if value.nil?

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
      "interactive_search_final_answer" => "Question limit reached answer",
      "search_query_expansion" => "Search term expansion",
      "duplicate_question_guard" => "Duplicate question check",
      "vector_search_query_embedding" => "Search matching preparation",
    }.fetch(event_kind.to_s, event_kind.to_s.humanize)
  end
end
