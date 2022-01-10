class Commodity
  class SearchReference < ::SearchReference
    attributes :productline_suffix

    collection_path '/admin/commodities/:referenced_id-:productline_suffix/search_references'

    type name.demodulize.tableize

    # We special case the commodity with the override below because its id is formed of the composite keys of
    # goods_nomenclature_item_id and the productline_suffix. Without this we would fail to be able to
    # manage subheading commodities that have the same goods_nomenclature_item_id.
    def referenced_id=(id_or_composite_id)
      if id_or_composite_id.to_s.match?(%r{\d{10}-\d{2}})
        referenced_id, productline_suffix = id_or_composite_id.split('-', 2)

        attributes[:referenced_id] = referenced_id
        attributes[:productline_suffix] = productline_suffix
      else
        attributes[:referenced_id] = id_or_composite_id
      end
    end
  end
end
