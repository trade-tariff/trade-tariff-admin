module QuotaOrderNumbers
  class QuotaOrderNumberOrigin
    include Her::JsonApi::Model

    attributes :geographical_area_id,
               :geographical_area_description,
               :validity_start_date,
               :validity_end_date
  end
end
