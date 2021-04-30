class Chapter
  class SearchReference < ::SearchReference
    collection_path '/admin/chapters/:referenced_id/search_references'
    type name.demodulize.tableize
  end
end
