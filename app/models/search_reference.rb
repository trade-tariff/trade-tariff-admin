class SearchReference
  include ApiEntity

  attr_accessor :title, :referenced_id
  attr_writer :referenced_class

  def referenced_entity
    referenced_class.find(referenced_id)
  end

  def referenced_class
    attributes['referenced_class'].constantize
  end
end
