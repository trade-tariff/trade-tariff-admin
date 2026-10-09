class SearchReference
  include ApiEntity

  # Virtual attributes used by the Admin UI only (not part of the API payload).
  attr_accessor :release_services, :release_to_uk, :release_to_xi

  # Read-only attributes returned by the backend. They are derived from the
  # referenced goods nomenclature, so they are never sent back on save.
  READ_ONLY_ATTRIBUTES = %w[
    goods_nomenclature_item_id
    goods_nomenclature_sid
    productline_suffix
    usage
  ].freeze

  attributes :title,
             :referenced_id,
             :referenced_class,
             *READ_ONLY_ATTRIBUTES.map(&:to_sym)

  def normalize_serialized_attributes(attrs)
    (%w[release_services release_to_uk release_to_xi] + READ_ONLY_ATTRIBUTES).each do |key|
      attrs.delete(key)
      attrs.delete(key.to_sym)
    end
  end

  def fpo?
    usage == "fpo"
  end

  def commodity_code_with_suffix
    return goods_nomenclature_item_id if productline_suffix.blank?

    "#{goods_nomenclature_item_id}-#{productline_suffix}"
  end
end
