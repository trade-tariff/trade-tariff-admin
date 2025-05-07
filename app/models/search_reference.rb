class SearchReference
  include ApiEntity

  attributes :title,
             :referenced_id,
             :referenced_class

  def referenced_entity
    referenced_class.find(referenced_id)
  end

  def referenced_class
    attributes['referenced_class'].constantize
  end
end
