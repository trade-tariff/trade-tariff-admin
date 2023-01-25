module QuotaOrderNumbers
  class QuotaOrderNumber
    include Her::JsonApi::Model

    attributes :id,
               :quota_order_number_sid,
               :validity_start_date,
               :validity_end_date
  end
end
