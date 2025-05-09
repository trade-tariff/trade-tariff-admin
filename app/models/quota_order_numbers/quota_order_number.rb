module QuotaOrderNumbers
  class QuotaOrderNumber
    include ApiEntity

    attr_accessor :id,
                  :quota_order_number_sid,
                  :validity_start_date,
                  :validity_end_date
  end
end
