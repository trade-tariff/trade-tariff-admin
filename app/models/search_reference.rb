class SearchReference
  include Her::JsonApi::Model

  collection_path '/admin/search_references'
  type name.demodulize.tableize

  attributes :title, :referenced_id, :referenced_class

  def referenced_entity
    referenced_class.find(referenced_id)
  end

  def referenced_class
    attributes['referenced_class'].constantize
  end

  # CSV export/import
  alias_method :goodsnomenclature_code, :referenced_id
  alias_method :goodsnomenclature_type, :referenced_class
end
