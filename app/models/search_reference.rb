class SearchReference
  include Her::JsonApi::TariffModel

  collection_path '/admin/search_references'
  type name.demodulize.tableize

  attributes :title, :referenced_id, :referenced_class

  validates :title, presence: true

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
