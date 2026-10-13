module SearchReferencesHelper
  # Path to the nested screen where the operator manages this reference
  # alongside the others for the same chapter, heading or commodity.
  def search_reference_parent_path(search_reference)
    code = search_reference.goods_nomenclature_item_id
    return if code.blank?

    case search_reference.referenced_class
    when "Chapter"
      references_chapter_search_references_path(code.first(2))
    when "Heading"
      references_heading_search_references_path(code.first(4))
    when "Subheading", "Commodity"
      references_commodity_search_references_path(search_reference.commodity_code_with_suffix)
    end
  end
end
