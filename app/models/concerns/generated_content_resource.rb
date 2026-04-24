module GeneratedContentResource
  extend ActiveSupport::Concern

  SCORE_BANDS = [
    [0.85, "Very High", "green"],
    [0.5, "High", "blue"],
    [0.3, "Medium", "yellow"],
  ].freeze

  included do
    include RecordDateFormatting

    attr_accessor :goods_nomenclature_id
  end

  class_methods do
    def listing(params)
      records = all(
        page: params[:page] || 1,
        type: params[:type] || "commodity",
        sort: params[:sort] || "score",
        direction: params[:direction] || "asc",
        status: params[:status],
        score_category: params[:score_category],
        q: params[:q],
      )

      {
        data: records.map(&:as_listing_json),
        pagination: pagination_for(records),
      }
    rescue Faraday::Error => e
      Rails.logger.error("Failed to fetch #{generated_content_collection_name}: #{e.message}")
      { data: [], pagination: { page: 1, per_page: 20, total_count: 0, total_pages: 0 } }
    end

    def generated_content_collection_name
      name.demodulize.underscore.pluralize.tr("_", "-")
    end
  end

  def as_listing_json
    {
      goods_nomenclature_sid:,
      goods_nomenclature_item_id:,
      score: listing_score,
      needs_review:,
      stale:,
      manually_edited:,
      approved:,
      expired:,
      listing_description_key => listing_description.to_s.truncate(80),
    }
  end

  def generate_score
    api.post("#{generated_content_member_path}/score")
  end

  def regenerate
    api.post("#{generated_content_member_path}/regenerate")
  end

  def approve
    api.post("#{generated_content_member_path}/approve")
  end

  def reject
    api.post("#{generated_content_member_path}/reject")
  end

  def score_label(value = score_value_for_tags)
    return "No score" if value.nil?

    matched_band = SCORE_BANDS.find { |threshold, _label, _colour| value >= threshold }
    matched_band ? matched_band[1] : "Low"
  end

  def score_tag_colour(value = score_value_for_tags)
    return "grey" if value.nil?

    matched_band = SCORE_BANDS.find { |threshold, _label, _colour| value >= threshold }
    matched_band ? matched_band[2] : "grey"
  end

private

  def generated_content_member_path
    raise NotImplementedError, "#{self.class} must define #generated_content_member_path"
  end

  def listing_description
    raise NotImplementedError, "#{self.class} must define #listing_description"
  end

  def listing_description_key
    raise NotImplementedError, "#{self.class} must define #listing_description_key"
  end

  def listing_score
    score
  end

  def score_value_for_tags
    listing_score
  end
end
