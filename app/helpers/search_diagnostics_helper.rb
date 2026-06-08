module SearchDiagnosticsHelper
  EVENT_DETAIL_KEYS = {
    "search_started" => %i[query search_type],
    "query_expanded" => %i[original_query expanded_query reason duration_ms],
    "query_refined" => %i[original_query refined_query answer_count],
    "query_expansion_decided" => %i[query expand reason result_count max_score],
    "api_call_completed" => %i[model response_type attempt_number duration_ms error_message error_message_truncated],
    "description_intercept_checked" => %i[matched term excluded filtering filter_prefix_count guidance_level guidance_location escalate_to_webchat],
    "question_returned" => %i[question_count attempt_number],
    "answer_returned" => %i[answer_count confidence_levels attempt_number],
    "search_completed" => %i[query search_type results_type final_result_type total_attempts total_questions result_count max_score total_duration_ms description_intercept_matched description_intercept_term description_intercept_excluded description_intercept_filtering description_intercept_filter_prefix_count description_intercept_guidance_level description_intercept_guidance_location description_intercept_escalate_to_webchat error_message error_message_truncated],
    "retrieval_leg_completed" => %i[leg status result_count duration_ms error_message error_message_truncated],
    "result_selected" => %i[goods_nomenclature_item_id goods_nomenclature_class],
    "search_failed" => %i[search_type error_type error_message error_message_truncated],
  }.freeze

  FIELD_LABELS = {
    attempt_number: "Attempt",
    duration_ms: "Duration",
    total_duration_ms: "Total duration",
    final_result_type: "Final result",
    expand: "Expand query",
  }.freeze

  SIGNIFICANT_TIMELINE_EVENTS = %w[
    exact_match_selected
    fuzzy_results_returned
    api_call_completed
    retrieval_leg_completed
    retrieval_results_returned
    question_returned
    answer_returned
    search_completed
    search_failed
  ].freeze

  def search_diagnostic_event_summary(event)
    fields = search_diagnostic_fields(event)

    case event[:event].to_s
    when "search_started"
      ["Search started", fields[:query]].compact_blank.join(" - ")
    when "query_expanded"
      query_change_summary("Query expanded", fields[:original_query], fields[:expanded_query])
    when "query_refined"
      "Query refined - added #{pluralize(fields[:answer_count].to_i, 'answer')}"
    when "query_expansion_decided"
      decision = truthy?(fields[:expand]) ? "used" : "skipped"
      ["Query expansion #{decision}", readable_value(fields[:reason])].compact_blank.join(" - ")
    when "api_call_completed"
      ["Model returned #{readable_value(fields[:response_type]) || 'response'}", attempt_label(fields)].compact_blank.join(" - ")
    when "exact_match_selected"
      code = target_label(fields)
      source = fields[:match_source].to_s.humanize.downcase.presence || "source"
      ["Exact match", source, fields[:matched_value], code].compact_blank.join(" - ")
    when "fuzzy_results_returned"
      "Fuzzy results returned - #{pluralize(fields[:result_count].to_i, 'result')}"
    when "interactive_configuration_used"
      "Interactive configuration used"
    when "retrieval_results_returned"
      [
        fields[:retrieval_method].to_s.humanize.presence,
        fields[:stage].to_s.humanize.presence,
        fields[:leg].to_s.humanize.presence,
        pluralize(fields[:result_count].to_i, "result"),
      ].compact_blank.join(" - ")
    when "question_returned"
      "Questions returned - #{pluralize(fields[:question_count].to_i, 'question')}"
    when "answer_returned"
      "Answers returned - #{pluralize(fields[:answer_count].to_i, 'answer')}"
    when "description_intercept_checked"
      description_intercept_summary(fields)
    when "search_completed"
      result_type = fields[:results_type].presence || fields[:final_result_type].presence
      ["Search completed", readable_value(result_type) || pluralize(fields[:result_count].to_i, "result")].compact_blank.join(" - ")
    when "retrieval_leg_completed"
      ["#{readable_value(fields[:leg]).to_s.capitalize} retrieval #{status_label(fields[:status])}", pluralize(fields[:result_count].to_i, "result")].compact_blank.join(" - ")
    when "result_selected"
      ["Result selected", [readable_value(fields[:goods_nomenclature_class]).to_s.downcase.presence, fields[:goods_nomenclature_item_id]].compact_blank.join(" ")].compact_blank.join(" - ")
    when "search_failed"
      ["Search failed", fields[:error_type]].compact_blank.join(" - ")
    else
      search_diagnostic_event_name(event)
    end
  end

  def search_diagnostic_event_name(event)
    event[:event].to_s.humanize.presence || "Event"
  end

  def search_diagnostic_search_type(event)
    case event[:search_type].presence
    when "interactive" then "Internal"
    when "classic" then "Classic"
    else
      event[:search_type].to_s.humanize.presence || "-"
    end
  end

  def search_diagnostic_events_with_context(events)
    current_search_type = nil

    Array(events).map do |event|
      event = normalise_search_diagnostic_hash(event).dup
      current_search_type = event[:search_type].presence || current_search_type

      if event[:event].to_s == "result_selected" && event[:search_type].blank?
        event[:search_type] = current_search_type
      end

      event
    end
  end

  def search_diagnostic_overview(events)
    events = Array(events).map { |event| normalise_search_diagnostic_hash(event) }

    {
      query: overview_query(events),
      outcome_tags: overview_outcome_tags(events),
      route_tags: overview_route_tags(events),
      results: overview_results(events),
      selected_results: overview_selected_results(events),
    }
  end

  def search_diagnostic_overview_tag(tag)
    content_tag(:strong, tag[:label], class: "govuk-tag govuk-tag--#{tag[:colour]} govuk-!-margin-right-1")
  end

  def search_diagnostic_overview_selected_result_link(result)
    link_to(result[:id], result[:href], class: "govuk-link", target: "_blank", rel: "noopener noreferrer")
  end

  def search_diagnostic_event_time(event)
    timestamp = event[:timestamp].to_s
    return "-" if timestamp.blank?

    Time.zone.parse(timestamp).strftime("%H:%M:%S.%L")
  rescue ArgumentError
    timestamp
  end

  def search_diagnostic_time_range(diagnostic)
    [diagnostic.start_time, diagnostic.end_time].filter_map { |timestamp| diagnostic_datetime(timestamp) }.join(" to ")
  end

  def search_diagnostic_timeline_events(events)
    timed_events = Array(events).filter_map do |event|
      timestamp = diagnostic_timestamp(event[:timestamp])
      next if timestamp.blank?

      {
        name: search_diagnostic_event_name(event),
        summary: search_diagnostic_event_summary(event),
        search_type: search_diagnostic_search_type(event),
        timestamp: timestamp,
        time: search_diagnostic_event_time(event),
        significant: SIGNIFICANT_TIMELINE_EVENTS.include?(event[:event].to_s),
      }
    end
    return [] if timed_events.blank?

    sorted_events = timed_events.sort_by { |event| event[:timestamp] }.each_with_index.map do |event, index|
      event.merge(id: search_diagnostic_event_dom_id(index))
    end

    timeline_events_by_order(sorted_events)
  end

  def search_diagnostic_event_dom_id(index)
    "search-event-#{index}"
  end

  def search_diagnostic_significant_timeline_events(events)
    significant_events = events.select { |event| event[:significant] }

    significant_events.presence || events
  end

  def search_diagnostic_event_details(event)
    fields = search_diagnostic_fields(event)

    content = case event[:event].to_s
              when "exact_match_selected"
                exact_match_details(fields)
              when "fuzzy_results_returned"
                fuzzy_results_details(fields)
              when "interactive_configuration_used"
                key_value_list(search_diagnostic_details(fields))
              when "retrieval_results_returned"
                retrieval_results_details(fields)
              when "question_returned"
                questions_details(fields)
              when "answer_returned"
                answers_details(fields)
              when *EVENT_DETAIL_KEYS.keys
                generic_event_details(event[:event].to_s, fields)
              end

    safe_join([
      content.presence,
      raw_event_details(event),
    ].compact)
  end

  def search_diagnostic_fields(event)
    normalise_search_diagnostic_hash(event[:fields] || {})
  end

private

  def diagnostic_datetime(timestamp)
    parsed = diagnostic_timestamp(timestamp)
    return if parsed.blank?

    "#{parsed.to_date.to_formatted_s(:govuk)} at #{parsed.strftime('%H:%M')}"
  end

  def diagnostic_timestamp(timestamp)
    return if timestamp.blank?

    Time.zone.parse(timestamp.to_s)
  rescue ArgumentError
    nil
  end

  def timeline_events_by_order(events)
    return events.map { |event| event.merge(position: 0) } if events.one?

    event_count = events.size - 1

    events.each_with_index.map do |event, index|
      event.merge(position: ((index.to_f / event_count) * 100).round)
    end
  end

  def exact_match_details(fields)
    rows = {
      "Source" => fields[:match_source],
      "Matched value" => fields[:matched_value],
      "Target" => goods_nomenclature_link(fields),
      "SID" => fields[:goods_nomenclature_sid],
      "Self-text" => self_text_link(fields),
      "Labels" => label_link(fields),
    }

    key_value_list(rows)
  end

  def fuzzy_results_details(fields)
    details = search_diagnostic_details(fields)
    sections = %i[goods_nomenclature_match reference_match].filter_map do |match_type|
      groups = normalise_search_diagnostic_hash(details[match_type])
      next if groups.blank?

      content_tag(:div, class: "govuk-!-margin-bottom-3") do
        safe_join([
          content_tag(:h4, match_type.to_s.humanize, class: "govuk-heading-s govuk-!-margin-bottom-2"),
          safe_join(groups.map { |level, results| result_group(level, results, include_admin_links: false) }),
        ])
      end
    end

    safe_join(sections.presence || [content_tag(:p, "No grouped results were logged.", class: "govuk-body-s")])
  end

  def retrieval_results_details(fields)
    details = search_diagnostic_details(fields)
    results = Array(details[:results])

    safe_join([
      key_value_list(
        "Retrieval method" => fields[:retrieval_method],
        "Stage" => fields[:stage],
        "Leg" => fields[:leg],
        "Iteration" => fields[:iteration],
        "Result count" => fields[:result_count],
      ),
      result_table(results),
    ])
  end

  def questions_details(fields)
    questions = Array(search_diagnostic_details(fields)[:questions])
    return content_tag(:p, "No question details were logged.", class: "govuk-body-s") if questions.blank?

    ordered_list(questions.map { |question| question[:question] || question[:text] || question.to_s })
  end

  def answers_details(fields)
    answers = Array(search_diagnostic_details(fields)[:answers])

    safe_join([
      key_value_list(fields.slice(:answer_count, :confidence_levels, :attempt_number)),
      answers.blank? ? content_tag(:p, "No answer details were logged.", class: "govuk-body-s") : result_table(answers),
    ])
  end

  def result_group(level, results, include_admin_links: true)
    safe_join([
      content_tag(:h5, level.to_s.humanize, class: "govuk-heading-s govuk-!-margin-bottom-1"),
      result_table(Array(results), include_admin_links:),
    ])
  end

  def result_table(results, include_admin_links: true)
    return content_tag(:p, "No results were logged.", class: "govuk-body-s") if results.blank?

    content_tag(:table, class: "govuk-table govuk-!-margin-bottom-4 app-diagnostics-table") do
      safe_join([
        content_tag(:thead, class: "govuk-table__head") do
          content_tag(:tr, class: "govuk-table__row") do
            safe_join(result_table_headings(include_admin_links).map { |heading| content_tag(:th, heading, class: "govuk-table__header", scope: "col") })
          end
        end,
        content_tag(:tbody, class: "govuk-table__body") do
          safe_join(results.map { |result| result_row(normalise_search_diagnostic_hash(result), include_admin_links:) })
        end,
      ])
    end
  end

  def result_table_headings(include_admin_links)
    headings = %w[Code Type Score]
    return headings unless include_admin_links

    headings + %w[Self-text Labels]
  end

  def result_row(result, include_admin_links: true)
    cells = [
      content_tag(:td, goods_nomenclature_link(result), class: "govuk-table__cell"),
      content_tag(:td, result[:goods_nomenclature_class].presence || "-", class: "govuk-table__cell"),
      content_tag(:td, result[:score].presence || result[:confidence].presence || "-", class: "govuk-table__cell"),
    ]

    if include_admin_links
      cells << content_tag(:td, self_text_link(result), class: "govuk-table__cell")
      cells << content_tag(:td, label_link(result), class: "govuk-table__cell")
    end

    content_tag(:tr, class: "govuk-table__row") do
      safe_join(cells)
    end
  end

  def key_value_list(rows)
    rows = rows.filter_map do |key, value|
      next if value.blank?

      content_tag(:div, class: "govuk-summary-list__row") do
        safe_join([
          content_tag(:dt, field_label(key), class: "govuk-summary-list__key"),
          content_tag(:dd, diagnostic_value(key, value), class: "govuk-summary-list__value"),
        ])
      end
    end

    return content_tag(:p, "No details were logged.", class: "govuk-body-s") if rows.blank?

    content_tag(:dl, safe_join(rows), class: "govuk-summary-list govuk-summary-list--no-border govuk-!-margin-bottom-4")
  end

  def ordered_list(items)
    content_tag(:ol, class: "govuk-list govuk-list--number") do
      safe_join(items.map { |item| content_tag(:li, item) })
    end
  end

  def diagnostic_value(key, value)
    return value if value.is_a?(ActiveSupport::SafeBuffer)
    return value.map { |item| readable_value(item) }.join(", ") if value.is_a?(Array)
    return value.map { |key, item| "#{readable_value(key)}: #{readable_value(item)}" }.join(", ") if value.is_a?(Hash)
    return "#{number_with_delimiter(value)} ms" if key.to_s.end_with?("_ms")
    return value if key.to_sym == :description_intercept

    readable_value(value)
  end

  def raw_event_details(event)
    tag.details(class: "govuk-details govuk-!-margin-bottom-0") do
      safe_join([
        content_tag(:summary, class: "govuk-details__summary") do
          content_tag(:span, "View raw fields", class: "govuk-details__summary-text")
        end,
        content_tag(:div, class: "govuk-details__text") do
          content_tag(:pre, JSON.pretty_generate(search_diagnostic_fields(event)), class: "govuk-body-s")
        end,
      ])
    end
  end

  def goods_nomenclature_link(result)
    endpoint = result[:target_endpoint].presence || endpoint_for_class(result[:goods_nomenclature_class])
    id = result[:target_id].presence || result[:goods_nomenclature_item_id].presence || result[:commodity_code]
    return id if endpoint.blank? && id.present?
    return "-" if endpoint.blank? || id.blank?

    link_to(id, "#{TradeTariffAdmin.frontend_host}/#{endpoint}/#{id}", class: "govuk-link", target: "_blank", rel: "noopener noreferrer")
  end

  def self_text_link(result)
    id = result[:self_text_id] || result[:goods_nomenclature_sid]
    return "-" if id.blank?

    link_to("View self-text", goods_nomenclature_self_text_path(id), class: "govuk-link")
  end

  def label_link(result)
    id = result[:goods_nomenclature_item_id] || result[:target_id] || result[:commodity_code]
    return "-" if id.blank?

    link_to("View labels", goods_nomenclature_label_path(id), class: "govuk-link")
  end

  def search_diagnostic_details(fields)
    normalise_search_diagnostic_hash(fields[:details] || {})
  end

  def overview_query(events)
    events.filter_map { |event| search_diagnostic_fields(event)[:query].presence }.first
  end

  def overview_outcome_tags(events)
    tags = []
    result_count = overview_result_count(events)

    tags << { label: "Failed", colour: "red" } if events.any? { |event| event[:event].to_s == "search_failed" }
    tags << { label: "Zero results", colour: "yellow" } if result_count&.zero?
    tags << { label: "Result selected", colour: "green" } if events.any? { |event| event[:event].to_s == "result_selected" }
    tags << { label: "Results returned", colour: "green" } if result_count.to_i.positive?

    tags
  end

  def overview_route_tags(events)
    type_tags = events.pluck(:search_type).compact_blank.uniq.filter_map do |search_type|
      case search_type
      when "classic" then { label: "Classic", colour: "blue" }
      when "interactive" then { label: "Internal", colour: "blue" }
      end
    end

    behaviour_tags = [
      ({ label: "Exact match", colour: "turquoise" } if events.any? { |event| event[:event].to_s == "exact_match_selected" }),
      ({ label: "Fuzzy", colour: "purple" } if fuzzy_search?(events)),
      ({ label: "Description intercept", colour: "orange" } if description_intercept_matched?(events)),
      ({ label: "Query expanded", colour: "grey" } if events.any? { |event| event[:event].to_s == "query_expanded" }),
      ({ label: "Questions returned", colour: "grey" } if events.any? { |event| event[:event].to_s == "question_returned" }),
      ({ label: "Answers returned", colour: "grey" } if events.any? { |event| event[:event].to_s == "answer_returned" }),
    ].compact

    type_tags + behaviour_tags
  end

  def overview_results(events)
    count = overview_result_count(events)
    return if count.blank? && count != 0

    pluralize(count, "#{overview_result_type(events)} result")
  end

  def overview_selected_results(events)
    events.select { |event| event[:event].to_s == "result_selected" }.filter_map do |event|
      fields = search_diagnostic_fields(event)
      id = target_id(fields)
      href = goods_nomenclature_href(fields)
      next if id.blank? || href.blank?

      { id:, href: }
    end
  end

  def endpoint_for_class(goods_nomenclature_class)
    goods_nomenclature_class.to_s.underscore.pluralize.presence
  end

  def goods_nomenclature_href(result)
    endpoint = result[:target_endpoint].presence || endpoint_for_class(result[:goods_nomenclature_class])
    id = target_id(result)
    return if endpoint.blank? || id.blank?

    "#{TradeTariffAdmin.frontend_host}/#{endpoint}/#{id}"
  end

  def target_id(result)
    result[:target_id].presence || result[:goods_nomenclature_item_id].presence || result[:commodity_code]
  end

  def target_label(result)
    endpoint = result[:target_endpoint].presence || endpoint_for_class(result[:goods_nomenclature_class])
    id = target_id(result)

    [endpoint, id].compact_blank.join("/")
  end

  def overview_result_count(events)
    completed_count = overview_result_count_for(events, "search_completed")
    return completed_count.to_i if logged_value?(completed_count)

    fuzzy_count = overview_result_count_for(events, "fuzzy_results_returned")
    fuzzy_count.to_i if logged_value?(fuzzy_count)
  end

  def overview_result_count_for(events, event_name)
    event = events.reverse_each.find do |item|
      item[:event].to_s == event_name && logged_value?(search_diagnostic_fields(item)[:result_count])
    end

    search_diagnostic_fields(event)[:result_count] if event
  end

  def logged_value?(value)
    value.present? || (value.respond_to?(:zero?) && value.zero?)
  end

  def overview_result_type(events)
    results_type = events.reverse_each.filter_map { |event| search_diagnostic_fields(event)[:results_type].presence }.first

    case results_type.to_s
    when "fuzzy_search" then "fuzzy"
    when "exact_search" then "exact"
    else
      fuzzy_search?(events) ? "fuzzy" : "search"
    end
  end

  def fuzzy_search?(events)
    events.any? { |event| event[:event].to_s == "fuzzy_results_returned" } ||
      events.any? { |event| search_diagnostic_fields(event)[:results_type].to_s == "fuzzy_search" }
  end

  def description_intercept_matched?(events)
    events.any? do |event|
      event[:event].to_s == "description_intercept_checked" &&
        truthy?(search_diagnostic_fields(event)[:matched])
    end
  end

  def generic_event_details(event_name, fields)
    key_value_list(detail_rows(event_name, fields))
  end

  def detail_rows(event_name, fields)
    rows = fields.slice(*EVENT_DETAIL_KEYS.fetch(event_name, []))
    return rows.merge(goods_nomenclature_item_id: goods_nomenclature_link(fields)) if event_name == "result_selected"
    return rows unless event_name == "search_completed"

    rows[:description_intercept] = description_intercept_value(fields) if fields.key?(:description_intercept_matched)
    rows.except(
      :description_intercept_matched,
      :description_intercept_term,
      :description_intercept_excluded,
      :description_intercept_filtering,
      :description_intercept_filter_prefix_count,
      :description_intercept_guidance_level,
      :description_intercept_guidance_location,
      :description_intercept_escalate_to_webchat,
    )
  end

  def field_label(key)
    FIELD_LABELS.fetch(key.to_sym, key.to_s.humanize)
  end

  def attempt_label(fields)
    return if fields[:attempt_number].blank?

    "attempt #{fields[:attempt_number]}"
  end

  def query_change_summary(label, original_query, changed_query)
    return label if original_query.blank? && changed_query.blank?
    return [label, original_query].compact_blank.join(" - ") if changed_query.blank?
    return [label, changed_query].compact_blank.join(" - ") if original_query.blank?

    "#{label} - #{original_query} to #{changed_query}"
  end

  def description_intercept_summary(fields)
    return "Description intercept not matched" unless truthy?(fields[:matched])

    ["Description intercept matched", fields[:term]].compact_blank.join(" - ")
  end

  def description_intercept_value(fields)
    return "Not matched" unless truthy?(fields[:description_intercept_matched])

    [
      "Matched",
      fields[:description_intercept_term],
      fields[:description_intercept_excluded].present? ? "excluded" : nil,
      fields[:description_intercept_filtering].present? ? "filtering" : nil,
    ].compact_blank.join(" ")
  end

  def status_label(value)
    value.to_s == "success" ? "succeeded" : readable_value(value)
  end

  def readable_value(value)
    return value if value.is_a?(ActiveSupport::SafeBuffer)
    return if value.nil?

    value.to_s.humanize.downcase
  end

  def truthy?(value)
    value == true || value.to_s == "true"
  end

  def normalise_search_diagnostic_hash(value)
    return nil if value.nil?

    value = JSON.parse(value) if value.is_a?(String) && value.strip.start_with?("{", "[")
    return value.map { |item| normalise_search_diagnostic_hash(item) } if value.is_a?(Array)
    return value unless value.respond_to?(:to_h)

    value.to_h.with_indifferent_access.transform_values { |item| normalise_search_diagnostic_hash(item) }
  rescue JSON::ParserError
    value
  end
end
