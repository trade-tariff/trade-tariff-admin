class SearchReference
  include ApiEntity

  # Virtual attributes used by the Admin UI only (not part of the API payload).
  attr_accessor :release_services, :release_to_uk, :release_to_xi

  attributes :title,
             :referenced_id,
             :referenced_class

  def serializable_hash
    hash = super

    attrs = hash.dig(:data, :attributes)
    return hash unless attrs.is_a?(Hash)

    %w[release_services release_to_uk release_to_xi].each do |key|
      attrs.delete(key)
      attrs.delete(key.to_sym)
    end

    hash
  end

  def referenced_entity
    referenced_class.find(referenced_id)
  end

  def referenced_class
    attributes["referenced_class"].constantize
  end
end
