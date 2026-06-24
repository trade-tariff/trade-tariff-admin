class SearchReference
  include ApiEntity

  # Virtual attributes used by the Admin UI only (not part of the API payload).
  attr_accessor :release_services, :release_to_uk, :release_to_xi

  attributes :title,
             :referenced_id,
             :referenced_class

  def normalize_serialized_attributes(attrs)
    %w[release_services release_to_uk release_to_xi].each do |key|
      attrs.delete(key)
      attrs.delete(key.to_sym)
    end
  end
end
