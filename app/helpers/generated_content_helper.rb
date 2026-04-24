module GeneratedContentHelper
  SCORE_CATEGORY_OPTIONS = [
    ["All", ""],
    ["Low", "bad"],
    ["Medium", "okay"],
    ["High", "good"],
    ["Very High", "amazing"],
    ["No score", "no_score"],
  ].freeze

  TAG_OPTIONS = [
    ["All", ""],
    ["Needs review", "needs_review"],
    ["Approved", "approved"],
    ["Stale", "stale"],
    ["Manually edited", "manually_edited"],
    ["Expired", "expired"],
  ].freeze

  GENERATED_CONTENT_TAGS = [
    [:needs_review, "Needs review", "orange"],
    [:manually_edited, "Manually edited", "purple"],
    [:stale, "Stale", "pink"],
    [:approved, "Approved", "green"],
    [:expired, "Expired", "grey"],
  ].freeze

  def generated_content_type_options(kind)
    return [%w[Commodity commodity], %w[Subheading subheading], %w[All all]] if kind == :self_text

    [%w[Commodity commodity], %w[Heading heading], %w[All all]]
  end

  def generated_content_score_options
    SCORE_CATEGORY_OPTIONS
  end

  def generated_content_tag_options
    TAG_OPTIONS
  end

  def generated_content_tags(record)
    tags = GENERATED_CONTENT_TAGS.filter_map do |attribute, label, colour|
      next unless record.public_send(attribute)

      content_tag(:strong, label, class: "govuk-tag govuk-tag--#{colour}")
    end

    return safe_join(tags, " ") if tags.any?

    content_tag(:strong, "Active", class: "govuk-tag govuk-tag--turquoise")
  end
end
