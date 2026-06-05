module SearchDiagnosticsHelper
  def search_diagnostic_event_summary(event)
    fields = search_diagnostic_fields(event)

    case event[:event].to_s
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
    when "search_completed"
      "Search completed - #{fields[:results_type].presence || fields[:final_result_type].presence || pluralize(fields[:result_count].to_i, 'result')}"
    else
      event[:event].presence || "Event"
    end
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
          safe_join(groups.map { |level, results| result_group(level, results) }),
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
    return content_tag(:p, "No answer details were logged.", class: "govuk-body-s") if answers.blank?

    result_table(answers)
  end

  def result_group(level, results)
    safe_join([
      content_tag(:h5, level.to_s.humanize, class: "govuk-heading-s govuk-!-margin-bottom-1"),
      result_table(Array(results)),
    ])
  end

  def result_table(results)
    return content_tag(:p, "No results were logged.", class: "govuk-body-s") if results.blank?

    content_tag(:table, class: "govuk-table govuk-!-margin-bottom-4") do
      safe_join([
        content_tag(:thead, class: "govuk-table__head") do
          content_tag(:tr, class: "govuk-table__row") do
            safe_join(%w[Code Type Score Self-text Labels].map { |heading| content_tag(:th, heading, class: "govuk-table__header", scope: "col") })
          end
        end,
        content_tag(:tbody, class: "govuk-table__body") do
          safe_join(results.map { |result| result_row(normalise_search_diagnostic_hash(result)) })
        end,
      ])
    end
  end

  def result_row(result)
    content_tag(:tr, class: "govuk-table__row") do
      safe_join([
        content_tag(:td, goods_nomenclature_link(result), class: "govuk-table__cell"),
        content_tag(:td, result[:goods_nomenclature_class].presence || "-", class: "govuk-table__cell"),
        content_tag(:td, result[:score].presence || result[:confidence].presence || "-", class: "govuk-table__cell"),
        content_tag(:td, self_text_link(result), class: "govuk-table__cell"),
        content_tag(:td, label_link(result), class: "govuk-table__cell"),
      ])
    end
  end

  def key_value_list(rows)
    rows = rows.filter_map do |key, value|
      next if value.blank?

      content_tag(:div, class: "govuk-summary-list__row") do
        safe_join([
          content_tag(:dt, key.to_s.humanize, class: "govuk-summary-list__key"),
          content_tag(:dd, diagnostic_value(value), class: "govuk-summary-list__value"),
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

  def diagnostic_value(value)
    return value if value.is_a?(ActiveSupport::SafeBuffer)
    return value.join(", ") if value.is_a?(Array)
    return JSON.pretty_generate(value) if value.is_a?(Hash)

    value
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
    id = result[:target_id].presence || result[:goods_nomenclature_item_id]
    return "-" if endpoint.blank? || id.blank?

    link_to(target_label(result), "#{TradeTariffAdmin.frontend_host}/#{endpoint}/#{id}", class: "govuk-link", target: "_blank", rel: "noopener noreferrer")
  end

  def self_text_link(result)
    id = result[:self_text_id] || result[:goods_nomenclature_sid]
    return "-" if id.blank?

    link_to("View self-text", goods_nomenclature_self_text_path(id), class: "govuk-link")
  end

  def label_link(result)
    id = result[:goods_nomenclature_item_id] || result[:target_id]
    return "-" if id.blank?

    link_to("View labels", goods_nomenclature_label_path(id), class: "govuk-link")
  end

  def search_diagnostic_details(fields)
    normalise_search_diagnostic_hash(fields[:details] || {})
  end

  def endpoint_for_class(goods_nomenclature_class)
    goods_nomenclature_class.to_s.underscore.pluralize.presence
  end

  def target_label(result)
    endpoint = result[:target_endpoint].presence || endpoint_for_class(result[:goods_nomenclature_class])
    id = result[:target_id].presence || result[:goods_nomenclature_item_id]

    [endpoint, id].compact_blank.join("/")
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
