module GreenLanes
  class GoodsNomenclature
    include Her::JsonApi::Model

    attributes :description, :goods_nomenclature_item_id, :goods_nomenclature_sid
  end
end
