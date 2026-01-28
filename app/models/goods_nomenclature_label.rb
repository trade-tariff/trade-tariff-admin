# UK Service - GoodsNomenclatureLabel for managing commodity labels
# Supports version history via oplog oid filter
class GoodsNomenclatureLabel
  include ApiEntity

  uk_only

  set_singular_path "admin/goods_nomenclatures/:goods_nomenclature_id/goods_nomenclature_label"

  attributes :goods_nomenclature_sid,
             :goods_nomenclature_item_id,
             :goods_nomenclature_type,
             :producline_suffix,
             :validity_start_date,
             :validity_end_date,
             :labels

  # Version metadata from API response
  attr_accessor :version_current,
                :version_oid,
                :version_previous_oid,
                :version_has_previous

  def current?
    version_current != false
  end

  def has_previous_version?
    version_has_previous == true
  end

  # Label field accessors
  def description
    labels&.dig("description")
  end

  def original_description
    labels&.dig("original_description")
  end

  def known_brands
    labels&.dig("known_brands") || []
  end

  def colloquial_terms
    labels&.dig("colloquial_terms") || []
  end

  def synonyms
    labels&.dig("synonyms") || []
  end

  # Text conversion for form fields (array <-> newline-separated text)
  def known_brands_text
    known_brands.join("\n")
  end

  def known_brands_text=(text)
    self.labels ||= {}
    labels["known_brands"] = text_to_array(text)
  end

  def colloquial_terms_text
    colloquial_terms.join("\n")
  end

  def colloquial_terms_text=(text)
    self.labels ||= {}
    labels["colloquial_terms"] = text_to_array(text)
  end

  def synonyms_text
    synonyms.join("\n")
  end

  def synonyms_text=(text)
    self.labels ||= {}
    labels["synonyms"] = text_to_array(text)
  end

  def description=(value)
    self.labels ||= {}
    labels["description"] = value
  end

  def validity_start_date
    super.to_date.to_formatted_s(:govuk)
  end

  def validity_end_date
    date = super

    return "" if date.nil?

    date.to_date.to_formatted_s(:govuk)
  end

  # Override find to extract version metadata from API response
  def self.find(goods_nomenclature_id, opts = {})
    entity = new({ goods_nomenclature_id: goods_nomenclature_id }.merge(opts))
    path = entity.singular_path

    filter_opts = {}
    filter_opts[:filter] = { oid: opts[:oid] } if opts[:oid].present?

    response = api.get(path, filter_opts)
    body = handle_body(response)
    parsed = parse_jsonapi(response)

    label = new(parsed)
    label.goods_nomenclature_id = goods_nomenclature_id

    # Extract version metadata from top-level meta
    if body.is_a?(Hash) && body["meta"]&.dig("version")
      version = body["meta"]["version"]
      label.version_current = version["current"]
      label.version_oid = version["oid"]
      label.version_previous_oid = version["previous_oid"]
      label.version_has_previous = version["has_previous_version"]
    end

    label
  end

  # Store goods_nomenclature_id for path building
  attr_accessor :goods_nomenclature_id

  def to_param
    goods_nomenclature_id || goods_nomenclature_item_id
  end

  def self.handle_body(resp)
    body = resp.try(:body) || resp.try(:[], :body)

    return "" if body.blank?
    return JSON.parse(body) if body.is_a?(String)

    body
  end
  private_class_method :handle_body

private

  def text_to_array(text)
    return [] if text.blank?

    text.split(/[\r\n]+/).map(&:strip).reject(&:blank?)
  end
end
